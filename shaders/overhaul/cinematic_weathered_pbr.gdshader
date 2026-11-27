shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Procedural gritty urban PBR shader (zero extra textures; kills flat plastic/Roblox cubes).
// Adds world-space dampness near ground, concrete/metal grain, grime streaks, and roughness variation.

uniform vec3 base_color : source_color = vec3(0.11, 0.14, 0.16);
uniform vec3 grime_color : source_color = vec3(0.045, 0.06, 0.07);
uniform float base_roughness : hint_range(0.08, 1.0) = 0.78;
uniform float wet_roughness : hint_range(0.05, 0.5) = 0.22;
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.08;
uniform float grime_strength : hint_range(0.0, 1.0) = 0.58;
uniform float ground_damp_height : hint_range(0.1, 3.0) = 1.15;
uniform float grain_scale : hint_range(0.5, 16.0) = 3.2;

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
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	return mix(nxy0, nxy1, f.z);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float coarse = vnoise(v_world_pos * (grain_scale * 0.45));
	float fine = vnoise(v_world_pos * (grain_scale * 2.4));
	float streaks = vnoise(vec3(v_world_pos.x * 1.8, v_world_pos.y * 0.35, v_world_pos.z * 1.8));
	float damp_band = 1.0 - smoothstep(0.0, ground_damp_height, max(0.0, v_world_pos.y));
	float top_wet = smoothstep(0.55, 0.95, v_world_norm.y) * smoothstep(0.38, 0.72, coarse);
	float wetness = clamp(damp_band * 0.72 + top_wet * 0.65, 0.0, 1.0);

	float grime = clamp((coarse * 0.5 + streaks * 0.5) * grime_strength + damp_band * 0.35, 0.0, 0.85);
	vec3 col = mix(base_color, grime_color, grime);
	col *= mix(0.86, 1.08, fine);
	// Wet surfaces darken physically instead of turning chalky gray
	col *= mix(1.0, 0.62, wetness);

	ALBEDO = col;
	METALLIC = metallic_amount * (1.0 - grime * 0.45);
	ROUGHNESS = clamp(mix(base_roughness, wet_roughness, wetness) + (fine - 0.5) * 0.12, 0.08, 0.96);
	SPECULAR = mix(0.42, 0.68, wetness);
}
