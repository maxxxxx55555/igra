shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 concrete_color : source_color = vec3(0.20, 0.23, 0.26);
uniform vec3 seam_color : source_color = vec3(0.09, 0.11, 0.13);
uniform vec3 damp_base_color : source_color = vec3(0.08, 0.10, 0.12);
uniform vec3 warm_window_color : source_color = vec3(0.92, 0.66, 0.34);
uniform float panel_width_m : hint_range(1.5, 6.0) = 3.2;
uniform float floor_height_m : hint_range(2.2, 4.5) = 2.9;
uniform float lit_window_chance : hint_range(0.0, 0.35) = 0.11;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float horiz = abs(v_world_normal.x) > abs(v_world_normal.z) ? v_world_pos.z : v_world_pos.x;
	vec2 wall_uv = vec2(horiz / panel_width_m, v_world_pos.y / floor_height_m);
	vec2 cell_id = floor(wall_uv);
	vec2 cell_f = fract(wall_uv);

	float seam = max(
		smoothstep(0.04, 0.0, min(cell_f.x, 1.0 - cell_f.x)),
		smoothstep(0.05, 0.0, min(cell_f.y, 1.0 - cell_f.y))
	);
	float in_win = step(0.24, cell_f.x) * step(cell_f.x, 0.76) * step(0.30, cell_f.y) * step(cell_f.y, 0.80) * step(1.0, cell_id.y);
	float is_lit = in_win * step(1.0 - lit_window_chance, hash21(cell_id));
	float damp = smoothstep(2.2, 0.0, v_world_pos.y);

	vec3 col = concrete_color + vec3((hash21(cell_id + 11.3) - 0.5) * 0.04);
	col = mix(col, seam_color, seam * 0.85);
	col = mix(col, damp_base_color, damp * 0.55);
	col = mix(col, vec3(0.05, 0.07, 0.09), in_win * (1.0 - is_lit));

	ALBEDO = col;
	EMISSION = warm_window_color * (is_lit * 0.65);
	ROUGHNESS = mix(0.88, 0.18, in_win);
	SPECULAR = mix(0.28, 0.70, in_win);
	METALLIC = 0.0;
}
