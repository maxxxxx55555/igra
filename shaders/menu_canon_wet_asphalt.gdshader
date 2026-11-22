shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform sampler2D puddle_mask_tex : filter_linear_mipmap, repeat_enable;

uniform vec2 uv_scale = vec2(4.0, 4.0);
uniform float world_puddle_scale : hint_range(0.01, 0.15) = 0.045;
uniform float wetness : hint_range(0.0, 1.0) = 0.62;
uniform float puddle_roughness : hint_range(0.06, 0.24) = 0.10;
uniform float dry_roughness_floor : hint_range(0.74, 0.96) = 0.84;
uniform float normal_strength : hint_range(0.2, 1.4) = 0.82;
uniform vec3 tint_color : source_color = vec3(0.68, 0.71, 0.72);
uniform vec3 mist_sky_tint : source_color = vec3(0.078, 0.129, 0.149);  // #142126
uniform vec3 sodium_bounce : source_color = vec3(0.788, 0.635, 0.290);  // #c9a24a
uniform float sodium_bounce_energy : hint_range(0.0, 0.25) = 0.06;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv_d = UV * uv_scale;
	// World-space macro coordinates produce broad, natural rain sheets instead of small repeating spots
	vec2 uv_macro = v_world_pos.xz * world_puddle_scale;
	float macro_a = texture(puddle_mask_tex, uv_macro).r;
	float macro_b = texture(puddle_mask_tex, uv_macro * 0.43 + vec2(0.37, 0.19)).r;
	float p_field = macro_a * 0.65 + macro_b * 0.35;

	float puddle = smoothstep(0.50, 0.74, p_field * (0.68 + 0.50 * wetness));
	float damp = smoothstep(0.30, 0.58, p_field * (0.68 + 0.50 * wetness));

	vec3 base_albedo = texture(albedo_tex, uv_d).rgb * tint_color;
	float base_rough = texture(roughness_tex, uv_d).r;

	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 3.8);

	// Deep nocturnal wet tarmac matching main menu reference (#14181a -> #0c1012 in puddles)
	vec3 dry_col = clamp(base_albedo, vec3(0.075), vec3(0.45));
	vec3 damp_col = dry_col * mix(1.0, 0.74, damp);
	vec3 puddle_col = damp_col * 0.48 + mist_sky_tint * (0.14 + 0.62 * fresnel);

	vec3 final_albedo = mix(damp_col, puddle_col, puddle);
	float final_rough = mix(max(base_rough, dry_roughness_floor), puddle_roughness, puddle);
	float final_spec = clamp(mix(0.34, 0.88, puddle) + fresnel * 0.10 * puddle, 0.0, 0.94);

	vec3 tex_n = texture(normal_tex, uv_d).rgb;
	vec3 final_n = mix(tex_n, vec3(0.5, 0.5, 1.0), puddle * 0.92);

	ALBEDO = clamp(final_albedo, vec3(0.075), vec3(0.88));
	EMISSION = sodium_bounce * (fresnel * puddle * sodium_bounce_energy);
	METALLIC = 0.0;
	SPECULAR = final_spec;
	ROUGHNESS = clamp(final_rough, 0.06, 0.95);
	NORMAL_MAP = final_n;
	NORMAL_MAP_DEPTH = normal_strength;
}
