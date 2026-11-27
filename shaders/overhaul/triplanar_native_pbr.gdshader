shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// World-Space Triplanar PBR Shader driving the repo's native 24 high-res WebP PBR textures
// (assets/textures/pbr/* and assets/textures/menu_canon_pbr/*).
// Eliminates UV stretching, sharp box seams, and floating edges via world-space ground/ceiling AO.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : filter_linear_mipmap, repeat_enable;

uniform vec3 tint_color : source_color = vec3(0.86, 0.85, 0.82);
uniform float uv_scale : hint_range(0.05, 4.0) = 0.36;
uniform float normal_depth : hint_range(0.0, 2.5) = 1.25;
uniform float roughness_scale : hint_range(0.2, 1.5) = 1.0;
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.06;

uniform float ground_y : hint_range(-10.0, 20.0) = 0.0;
uniform float contact_ao_height : hint_range(0.08, 2.0) = 0.62;
uniform float contact_ao_strength : hint_range(0.0, 0.95) = 0.74;
uniform float ceiling_y : hint_range(1.0, 30.0) = 3.55;
uniform float ceiling_ao_enable : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec3 v_world_norm;

vec4 triplanar_sample(sampler2D tex, vec3 p, vec3 blend) {
	return texture(tex, p.zy) * blend.x + texture(tex, p.xz) * blend.y + texture(tex, p.xy) * blend.z;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 wn = abs(v_world_norm);
	vec3 blend = pow(wn, vec3(4.0));
	blend /= max(0.0001, blend.x + blend.y + blend.z);
	vec3 wp = v_world_pos * uv_scale;

	vec3 alb = triplanar_sample(albedo_tex, wp, blend).rgb * tint_color;
	vec3 nrm = triplanar_sample(normal_tex, wp, blend).rgb;
	float rgh = triplanar_sample(roughness_tex, wp, blend).r * roughness_scale;

	float hg = max(0.0, v_world_pos.y - ground_y);
	float g_ao = smoothstep(0.0, contact_ao_height, hg);
	float damp = 1.0 - smoothstep(0.0, contact_ao_height * 2.0, hg);

	float hc = max(0.0, ceiling_y - v_world_pos.y);
	float c_ao = mix(1.0, smoothstep(0.0, 0.45, hc), ceiling_ao_enable);

	float total_ao = clamp(mix(1.0 - contact_ao_strength, 1.0, g_ao) * mix(0.58, 1.0, c_ao), 0.14, 1.0);
	alb *= mix(1.0, 0.62, damp * 0.72);
	alb *= mix(0.50, 1.0, total_ao);

	ALBEDO = alb;
	NORMAL_MAP = nrm;
	NORMAL_MAP_DEPTH = normal_depth;
	AO = total_ao;
	AO_LIGHT_AFFECT = 0.80;
	METALLIC = metallic_amount;
	ROUGHNESS = clamp(mix(rgh, min(rgh, 0.20), damp * 0.68), 0.08, 0.96);
	SPECULAR = mix(0.42, 0.72, damp);
}
