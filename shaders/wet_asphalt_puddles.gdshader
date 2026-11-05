shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 asphalt_color : source_color = vec4(0.12, 0.13, 0.15, 1.0);
uniform vec4 wet_asphalt_color : source_color = vec4(0.04, 0.05, 0.06, 1.0);
uniform vec4 puddle_tint : source_color = vec4(0.02, 0.03, 0.04, 1.0);

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D puddle_noise : hint_default_black, filter_linear_mipmap, repeat_enable;

uniform float uv_scale : hint_range(0.5, 50.0) = 8.0;
uniform float puddle_coverage : hint_range(0.0, 1.0) = 0.48;
uniform float puddle_sharpness : hint_range(1.0, 20.0) = 8.5;
uniform float ripple_speed : hint_range(0.0, 5.0) = 0.8;
uniform float ripple_strength : hint_range(0.0, 0.2) = 0.025;
uniform float porosity_darkening : hint_range(0.0, 1.0) = 0.65;

varying vec3 world_pos;

vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float perlin_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(dot(hash22(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
			dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec2 world_uv = world_pos.xz * 0.22;

	// Низкочастотная маска луж + учет Vertex Color (R-канал для ручного рисования луж)
	float n_low = perlin_noise(world_uv * 0.6) * 0.5 + 0.5;
	float n_mid = perlin_noise(world_uv * 2.1 + vec2(4.2, 1.7)) * 0.5 + 0.5;
	float raw_puddle = mix(n_low, n_mid, 0.35) * COLOR.r;
	float puddle_mask = clamp((raw_puddle - (1.0 - puddle_coverage)) * puddle_sharpness, 0.0, 1.0);
	float damp_zone = clamp((raw_puddle - (1.0 - puddle_coverage - 0.18)) * (puddle_sharpness * 0.5), 0.0, 1.0);

	vec3 base_tex = texture(albedo_tex, uv).rgb * asphalt_color.rgb;
	float base_rough = texture(roughness_tex, uv).r;
	vec3 base_norm = texture(normal_tex, uv).rgb;

	// Потемнение пористого асфальта от влаги вокруг луж
	vec3 damp_albedo = mix(base_tex, base_tex * wet_asphalt_color.rgb * (1.0 - porosity_darkening), damp_zone);
	ALBEDO = mix(damp_albedo, puddle_tint.rgb, puddle_mask * 0.85);

	// Микро-рябь на поверхности воды в лужах
	float t = TIME * ripple_speed;
	vec2 ripple_uv1 = world_pos.xz * 6.0 + vec2(t * 0.4, t * 0.25);
	vec2 ripple_uv2 = world_pos.xz * 9.5 - vec2(t * 0.3, t * 0.5);
	float r1 = perlin_noise(ripple_uv1);
	float r2 = perlin_noise(ripple_uv2);
	vec3 water_normal = normalize(vec3((r1 + r2) * ripple_strength, (r1 - r2) * ripple_strength, 1.0));
	vec3 water_normal_map = water_normal * 0.5 + 0.5;

	NORMAL_MAP = mix(base_norm, water_normal_map, puddle_mask * 0.96);
	ROUGHNESS = mix(mix( clamp(base_rough * 0.88, 0.45, 0.95), 0.22, damp_zone ), 0.035, puddle_mask);
	SPECULAR = mix(0.35, 0.95, puddle_mask);
	METALLIC = mix(0.02, 0.12, puddle_mask);
}
