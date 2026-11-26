shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

uniform vec3 sodium_color : source_color = vec3(0.831, 0.663, 0.306); // #d4a94e
uniform float cone_opacity : hint_range(0.0, 0.45) = 0.16;
uniform float edge_softness : hint_range(1.0, 5.0) = 2.6;
uniform float top_fade : hint_range(0.02, 0.30) = 0.08;
uniform float bottom_fade : hint_range(0.20, 0.95) = 0.88;
uniform float dust_shimmer : hint_range(0.0, 0.35) = 0.14;

void fragment() {
	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float fresnel_core = pow(clamp(ndotv, 0.0, 1.0), edge_softness);

	float v_in = smoothstep(0.0, top_fade, UV.y);
	float v_out = 1.0 - smoothstep(bottom_fade * 0.45, 1.0, UV.y);
	float v_falloff = v_in * pow(max(v_out, 0.0), 1.6);

	float mist = 1.0 - dust_shimmer * 0.5 + dust_shimmer * 0.5 * sin(UV.x * 18.8495 + TIME * 0.45) * cos(UV.y * 9.0 - TIME * 0.25);

	float alpha = clamp(fresnel_core * v_falloff * mist * cone_opacity, 0.0, 0.40);
	ALBEDO = sodium_color;
	ALPHA = alpha;
}
