shader_type spatial;
render_mode blend_mul, depth_draw_never, cull_back, unshaded, fog_disabled;

// Grounded multiplicative soft contact-shadow skirt placed 0.018m above street/floor.

uniform float shadow_opacity : hint_range(0.0, 0.95) = 0.74;
uniform float inner_rect : hint_range(0.05, 0.48) = 0.34;
uniform float softness : hint_range(0.04, 0.45) = 0.16;

void fragment() {
	vec2 d = abs(UV - vec2(0.5));
	float edge = mix(max(d.x, d.y), length(d), 0.34);
	float mask = 1.0 - smoothstep(inner_rect, inner_rect + softness, edge);
	ALBEDO = vec3(mix(1.0, 1.0 - shadow_opacity, clamp(mask, 0.0, 1.0)));
	ALPHA = 1.0;
}
