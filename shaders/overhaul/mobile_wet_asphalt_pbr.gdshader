shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 dry_asphalt_color : source_color = vec3(0.14, 0.165, 0.19);
uniform vec3 wet_puddle_color : source_color = vec3(0.065, 0.088, 0.115);
uniform vec3 sodium_grazing_tint : source_color = vec3(0.92, 0.74, 0.44);
uniform float puddle_coverage : hint_range(0.0, 1.0) = 0.44;
uniform float puddle_sharpness : hint_range(0.02, 0.35) = 0.09;
uniform float world_scale : hint_range(0.05, 2.0) = 0.28;
uniform float grain_strength : hint_range(0.0, 0.25) = 0.09;
uniform float grazing_strength : hint_range(0.0, 0.45) = 0.18;

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv_w = v_world_pos.xz * world_scale;
	float n_macro = value_noise(uv_w) * 0.65 + value_noise(uv_w * 2.3 + 7.1) * 0.35;
	float n_grain = value_noise(uv_w * 18.0) - 0.5;
	float threshold = 1.0 - puddle_coverage;
	float wet_mask = smoothstep(threshold - puddle_sharpness, threshold + puddle_sharpness, n_macro);
	vec3 base_col = mix(dry_asphalt_color + vec3(n_grain * grain_strength), wet_puddle_color, wet_mask);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = base_col + sodium_grazing_tint * (fresnel * wet_mask * grazing_strength);
	ROUGHNESS = mix(0.84, 0.10, wet_mask);
	SPECULAR = mix(0.38, 0.78, wet_mask);
	METALLIC = 0.0;
}
