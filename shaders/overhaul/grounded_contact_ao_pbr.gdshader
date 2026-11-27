shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Grounded Contact-AO & Seam-Blending Urban PBR Shader (0 extra textures).
// Eliminates sharp plastic transitions and "floating" objects without shadows:
// 1) Darkens base near ground_y (soft contact shadow & damp skirt)
// 2) Darkens top near ceiling_y (interior corner AO)
// 3) Softens UV edges (fake bevel AO so adjacent boxes blend cleanly)
// 4) Adds subtle procedural surface micro-relief via screen-space derivatives

uniform vec3 base_color : source_color = vec3(0.085, 0.112, 0.132);
uniform vec3 grime_color : source_color = vec3(0.032, 0.044, 0.052);
uniform float base_roughness : hint_range(0.10, 1.0) = 0.80;
uniform float wet_roughness : hint_range(0.06, 0.50) = 0.24;
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.08;
uniform float ground_y : hint_range(-10.0, 20.0) = 0.0;
uniform float contact_ao_height : hint_range(0.05, 1.5) = 0.42;
uniform float contact_ao_strength : hint_range(0.0, 0.95) = 0.68;
uniform float ceiling_y : hint_range(1.0, 30.0) = 3.45;
uniform float ceiling_ao_enable : hint_range(0.0, 1.0) = 0.0;
uniform float edge_bevel_ao : hint_range(0.0, 0.7) = 0.32;
uniform float grain_scale : hint_range(0.5, 18.0) = 4.2;
uniform float bump_strength : hint_range(0.0, 0.35) = 0.14;

varying vec3 v_world_pos;
varying vec3 v_world_norm;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
		f.z
	);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float coarse = vnoise(v_world_pos * (grain_scale * 0.38));
	float fine = vnoise(v_world_pos * (grain_scale * 2.1));
	float streaks = vnoise(vec3(v_world_pos.x * 1.9, v_world_pos.y * 0.32, v_world_pos.z * 1.9));

	// 1. Ground contact shadow & damp skirt (smooth transition into asphalt/floor)
	float h_ground = max(0.0, v_world_pos.y - ground_y);
	float ground_ao = smoothstep(0.0, contact_ao_height, h_ground);
	float damp_band = 1.0 - smoothstep(0.0, contact_ao_height * 2.2, h_ground);

	// 2. Optional ceiling corner AO for interior walls
	float h_ceil = max(0.0, ceiling_y - v_world_pos.y);
	float ceil_ao = mix(1.0, smoothstep(0.0, 0.36, h_ceil), ceiling_ao_enable);

	// 3. Soft UV-border crevice occlusion (kills razor transitions between modular faces)
	vec2 edge_d = min(fract(UV), 1.0 - fract(UV));
	float edge_mask = smoothstep(0.0, 0.055, min(edge_d.x, edge_d.y));
	float seam_ao = mix(1.0 - edge_bevel_ao, 1.0, edge_mask);

	float total_ao = clamp(mix(1.0 - contact_ao_strength, 1.0, ground_ao) * mix(0.62, 1.0, ceil_ao) * seam_ao, 0.14, 1.0);

	// 4. Wetness + weathered grime
	float top_wet = smoothstep(0.55, 0.95, v_world_norm.y) * smoothstep(0.36, 0.72, coarse);
	float wetness = clamp(damp_band * 0.65 + top_wet * 0.60, 0.0, 1.0);
	float grime = clamp((coarse * 0.45 + streaks * 0.55) * 0.58 + damp_band * 0.35, 0.0, 0.88);

	vec3 col = mix(base_color, grime_color, grime);
	col *= mix(0.88, 1.06, fine);
	col *= mix(1.0, 0.64, wetness);
	col *= mix(0.55, 1.0, total_ao);

	// 5. Screen-space micro-bump for tactile concrete/plaster/metal grain
	float h_bump = (coarse * 0.55 + fine * 0.45) * bump_strength;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	float dhdx = dFdx(h_bump);
	float dhdy = dFdy(h_bump);
	vec3 surf_grad = normalize(cross(dpdy, NORMAL) * dhdx + cross(NORMAL, dpdx) * dhdy + NORMAL * 0.001);
	NORMAL = normalize(NORMAL - surf_grad * 0.45);

	ALBEDO = col;
	AO = total_ao;
	AO_LIGHT_AFFECT = 0.72;
	METALLIC = metallic_amount * (1.0 - grime * 0.45);
	ROUGHNESS = clamp(mix(base_roughness, wet_roughness, wetness) + (fine - 0.5) * 0.10, 0.08, 0.96);
	SPECULAR = mix(0.38, 0.64, wetness);
}
