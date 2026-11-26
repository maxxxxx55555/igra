shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform sampler2D puddle_mask_tex : filter_linear_mipmap, repeat_enable;

uniform vec2 uv_scale = vec2(4.0, 4.0);
uniform vec2 puddle_uv_scale = vec2(0.75, 0.75);
uniform float wetness : hint_range(0.0, 1.0) = 0.52;
uniform float puddle_roughness : hint_range(0.10, 0.32) = 0.16;
uniform float dry_roughness_floor : hint_range(0.72, 0.96) = 0.84;
uniform float normal_strength : hint_range(0.1, 1.5) = 0.78;
uniform float ripple_strength : hint_range(0.0, 0.05) = 0.012;
uniform vec3 tint_color : source_color = vec3(1.18, 1.24, 1.30);
uniform vec3 night_sky_reflect : source_color = vec3(0.09, 0.14, 0.18); // cold #1a2133 bounce

void fragment() {
	vec2 uv_detail = UV * uv_scale;
	vec2 uv_macro = UV * puddle_uv_scale;

	vec3 base_albedo = texture(albedo_tex, uv_detail).rgb * tint_color;
	float base_rough = texture(roughness_tex, uv_detail).r;
	float puddle_raw = texture(puddle_mask_tex, uv_macro).r;

	// Tight, natural rainwater streaks instead of giant pale blotches
	float puddle_weight = smoothstep(0.48, 0.80, puddle_raw * (0.65 + 0.55 * wetness));

	// Grazing-angle Fresnel sheen gives readable wet road silhouette under streetlights
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 3.2);

	vec3 dry_col = clamp(base_albedo, vec3(0.08), vec3(0.88));
	vec3 wet_col = dry_col * 0.52 + night_sky_reflect * (0.22 + 0.55 * fresnel);
	vec3 final_albedo = mix(dry_col, wet_col, puddle_weight);

	float final_rough = mix(max(base_rough, dry_roughness_floor), puddle_roughness, puddle_weight);
	float final_spec = mix(0.38, 0.78, puddle_weight) + fresnel * 0.14 * puddle_weight;

	vec3 tex_n = texture(normal_tex, uv_detail).rgb;
	vec3 flat_n = vec3(0.5, 0.5, 1.0);
	float ripple = sin(uv_macro.x * 26.0 + TIME * 1.2) * cos(uv_macro.y * 22.0 - TIME * 0.9) * ripple_strength * puddle_weight;
	vec3 blended_n = mix(tex_n, clamp(flat_n + vec3(ripple, ripple, 0.0), 0.0, 1.0), puddle_weight * 0.92);

	ALBEDO = clamp(final_albedo, vec3(0.075), vec3(0.92));
	METALLIC = 0.0;
	SPECULAR = clamp(final_spec, 0.0, 0.92);
	ROUGHNESS = clamp(final_rough, 0.10, 0.96);
	NORMAL_MAP = blended_n;
	NORMAL_MAP_DEPTH = normal_strength;
}
