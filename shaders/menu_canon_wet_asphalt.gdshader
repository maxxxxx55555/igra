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
// The sodium sheen the street lamps throw back onto the wet tarmac. At 0.06 the
// road was a black hole under the fog: with one live lamp out of 48 (the light
// limiter's budget) the ground carried no light of its own, so every frame read
// as "flat gray mud". The sheen is the street's own light - a wet mirror of the
// lamps - and it costs no draw call and no light slot.
uniform float sodium_bounce_energy : hint_range(0.0, 0.60) = 0.40;

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

	float puddle = smoothstep(0.35, 0.75, p_field) * wetness;
	vec3 grain = mix(vec3(0.76), vec3(1.0), texture(albedo_tex, uv_d).rgb);
	vec3 dry_col = vec3(0.063, 0.082, 0.094);
	vec3 wet_col = vec3(0.035, 0.051, 0.063);
	ALBEDO = mix(dry_col, wet_col, puddle) * grain * tint_color;
	METALLIC = 0.0;
	SPECULAR = mix(0.34, 0.60, puddle);
	ROUGHNESS = mix(0.72, 0.12, puddle);
	NORMAL_MAP = mix(texture(normal_tex, uv_d).rgb, vec3(0.5, 0.5, 1.0), puddle * 0.92);
	NORMAL_MAP_DEPTH = normal_strength;
}
