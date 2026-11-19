shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Repeat counts across a 24 m frontage and 18 m elevation, independent of mesh UVs.
uniform float window_cols : hint_range(1.0, 24.0, 1.0) = 8.0;
uniform float window_rows : hint_range(1.0, 18.0, 1.0) = 6.0;
uniform vec4 wall_tint : source_color = vec4(0.252, 0.260, 0.272, 1.0);
uniform vec4 amber_glow : source_color = vec4(0.8510, 0.6078, 0.2196, 1.0);
uniform vec4 fluorescent : source_color = vec4(0.6078, 0.7216, 0.7804, 1.0);
uniform float lit_ratio : hint_range(0.0, 1.0) = 0.25;
uniform float flicker_speed : hint_range(0.0, 16.0) = 5.0;
uniform float rain_streaks : hint_range(0.0, 1.0) = 0.55;
uniform float ground_y = 0.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

float hash_cell(vec2 cell) {
	vec3 h = fract(vec3(cell.xyx) * vec3(0.1031, 0.1030, 0.0973));
	h += dot(h, h.yzx + 33.33);
	return fract((h.x + h.y) * h.z);
}

float band_noise(float x) {
	float t = fract(x);
	return mix(hash_cell(vec2(floor(x), 11.0)), hash_cell(vec2(floor(x) + 1.0, 11.0)),
			t * t * (3.0 - 2.0 * t));
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec2 facing = n.xz / max(length(n.xz), 0.0001);
	float frontage = dot(world_pos.xz, vec2(facing.y, -facing.x));
	float plane_id = floor(dot(world_pos.xz, facing) * 0.5 + 0.37);
	vec2 uv = vec2(frontage * window_cols / 24.0, (world_pos.y - ground_y) * window_rows / 18.0);
	vec2 id = floor(uv) + vec2(plane_id * 7.0, plane_id * 19.0);
	vec2 local = fract(uv) - vec2(0.5, 0.54);
	vec2 footprint = fwidth(uv);
	float aa = clamp(max(footprint.x, footprint.y) * 0.5, 0.001, 0.14);
	float face = (1.0 - smoothstep(0.18, 0.55, abs(n.y))) *
			(1.0 - smoothstep(0.20, 0.95, max(footprint.x, footprint.y)));
	float bay_profile = hash_cell(vec2(id.x, plane_id + 0.5));
	vec2 extent = vec2(mix(0.24, 0.35, bay_profile), 0.31);
	vec2 edge = abs(local) - extent;
	float dist = max(edge.x, edge.y);
	float opening = (1.0 - smoothstep(-aa, aa, dist)) * face;
	float inset = 1.0 - smoothstep(-0.036 - aa, -0.036 + aa, dist);
	float mullion = smoothstep(0.011 - aa, 0.011 + aa, abs(local.x - (bay_profile - 0.5) * 0.16));
	float glass = opening * inset * mullion;

	float stripe = band_noise(frontage * 1.7 + plane_id);
	float runoff = smoothstep(0.44, 0.90, stripe) * (0.65 + 0.35 * cos(world_pos.y * 0.47 + stripe * 8.0));
	float grime = (1.0 - smoothstep(0.0, 3.2, world_pos.y - ground_y)) * (0.23 + 0.35 * stripe);
	vec3 wall = wall_tint.rgb * (1.0 - grime) * (1.0 - runoff * rain_streaks * 0.47);
	vec2 brick = vec2(frontage / 0.46, (world_pos.y - ground_y) / 0.165);
	vec2 brick_aa = max(fwidth(brick), vec2(0.002));
	brick.x += mod(floor(brick.y), 2.0) * 0.5;
	vec2 joint_dist = 0.5 - abs(fract(brick) - 0.5);
	vec2 joint = smoothstep(vec2(0.017) - brick_aa, vec2(0.017) + brick_aa, joint_dist);
	float masonry = step(0.47, bay_profile) * face * (1.0 - smoothstep(0.22, 0.85, max(brick_aa.x, brick_aa.y)));
	wall *= mix(1.0, (0.78 + 0.22 * joint.x * joint.y) * (0.90 + 0.14 * hash_cell(floor(brick))), masonry);

	float bevel = clamp(1.0 + dist / 0.036, 0.0, 1.0);
	float lip = edge.x > edge.y ? -sign(local.x) * 0.08 : -sign(local.y) * 0.23;
	vec3 frame = wall_tint.rgb * (0.22 + bevel * (0.45 + lip));
	ALBEDO = mix(mix(wall, frame, opening), wall_tint.rgb * vec3(0.13, 0.16, 0.19), glass);
	ROUGHNESS = mix(mix(0.88, 0.53, opening), 0.12, glass);

	float roll = hash_cell(id);
	float faulty = 1.0 - step(lit_ratio * 0.2, roll);
	float live = 1.0 - step(lit_ratio, roll);
	float furnishing = hash_cell(id + vec2(17.0, 31.0));
	float clock = TIME * flicker_speed + furnishing * 23.0;
	float flicker = 0.93 + 0.035 * sin(clock * 2.1) - 0.095 * pow(0.5 + 0.5 * sin(clock * 4.3), 8.0);
	float shade = 1.0 - 0.62 * smoothstep(0.03 + furnishing * 0.23, 0.05 + furnishing * 0.23, local.y);
	EMISSION = glass * live * shade * mix(0.50, 1.12, furnishing) *
			mix(amber_glow.rgb, fluorescent.rgb * flicker * 0.68, faulty);
}
