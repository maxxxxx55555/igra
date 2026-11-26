shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform float puddle_coverage : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float puddle_sharpness : hint_range(1.0, 64.0, 0.1) = 24.0;
uniform float ripple_speed : hint_range(0.0, 4.0, 0.01) = 1.0;
uniform vec4 asphalt_tint : source_color = vec4(0.078431, 0.090196, 0.101961, 1.0);
uniform float wet_darkening : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float tex_scale : hint_range(0.05, 4.0) = 0.35;

varying vec2 world_xz;

float cell_hash(vec2 cell) {
	vec3 p = fract(vec3(cell.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Returns the interpolated value and its analytic gradient.
vec3 value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 f = fract(position);
	vec2 u = f * f * (3.0 - 2.0 * f);
	vec2 du = 6.0 * f * (1.0 - f);
	float a = cell_hash(cell);
	float b = cell_hash(cell + vec2(1.0, 0.0));
	float c = cell_hash(cell + vec2(0.0, 1.0));
	float d = cell_hash(cell + vec2(1.0, 1.0));
	float lower = mix(a, b, u.x);
	float upper = mix(c, d, u.x);

	return vec3(
		mix(lower, upper, u.y),
		du.x * mix(b - a, d - c, u.y),
		du.y * (upper - lower)
	);
}

float puddle_fbm(vec2 position) {
	const mat2 octave_basis = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));
	float sum = 0.0;
	float weight = 1.0;
	for (int octave = 0; octave < 4; octave++) {
		sum += weight * value_noise(position).x;
		position = octave_basis * position + vec2(13.7, 23.1);
		weight *= 0.5;
	}
	return sum / 1.875;
}

float ripple_wave(vec2 position, vec2 wave_vector, float phase) {
	float angle = dot(position, wave_vector);
	float visibility = 1.0 - smoothstep(1.0, 3.14159, fwidth(angle));
	return cos(angle + phase) * visibility;
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float basin = puddle_fbm(world_xz * 0.35);
	float edge = max(0.5 / puddle_sharpness, 0.5 * fwidth(basin));
	float wet = 1.0 - smoothstep(puddle_coverage - edge, puddle_coverage + edge, basin);
	if (puddle_coverage <= 0.0) {
		wet = 0.0;
	} else if (puddle_coverage >= 1.0) {
		wet = 1.0;
	}
	vec2 grain_position = world_xz * 110.0;
	vec2 grain_footprint = fwidth(grain_position);
	float grain_visibility = 1.0 - smoothstep(0.25, 1.0, max(grain_footprint.x, grain_footprint.y));
	vec2 grain_slope = value_noise(grain_position).yz * (0.075 * grain_visibility);

	vec2 tex_uv = world_xz * tex_scale;
	vec3 tex_albedo = texture(albedo_tex, tex_uv).rgb;
	float tex_rough = texture(roughness_tex, tex_uv).r;
	vec3 tex_normal = texture(normal_tex, tex_uv).rgb * 2.0 - 1.0;
	grain_slope += tex_normal.xy * (0.06 * grain_visibility);

	float t = TIME * ripple_speed;
	const vec2 wind = vec2(0.96, 0.28);
	const vec2 crosswind = vec2(0.60, -0.80);
	vec2 ripple_slope = wind * (0.012 * ripple_wave(world_xz, wind * 19.0, -2.0 * t));
	ripple_slope += crosswind * (0.005 * ripple_wave(world_xz, crosswind * 31.0, -2.7 * t + 1.4));

	vec2 slope = mix(grain_slope, ripple_slope, wet);
	vec3 normal_view = normalize(NORMAL);
	vec3 slope_view = mat3(VIEW_MATRIX) * vec3(slope.x, 0.0, slope.y);
	NORMAL = normalize(normal_view - (slope_view - normal_view * dot(normal_view, slope_view)));

	vec3 base_albedo = mix(asphalt_tint.rgb, asphalt_tint.rgb * tex_albedo * 3.2, 0.72);
	ALBEDO = base_albedo * (1.0 - wet_darkening * wet);
	ROUGHNESS = mix(mix(0.85, 0.06, wet), tex_rough, 0.35 * (1.0 - wet));
	METALLIC = 0.03 * wet;
	SPECULAR = mix(0.35, 0.9, wet);
}
