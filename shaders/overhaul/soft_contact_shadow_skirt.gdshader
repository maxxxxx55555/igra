shader_type spatial;
render_mode blend_mul, depth_draw_never, cull_back, unshaded, fog_disabled;

// Ultra-smooth multiplicative contact shadow skirt (no jagged black patches around corners).

uniform float shadow_opacity : hint_range(0.0, 0.85) = 0.56;
uniform float inner_rect : hint_range(0.05, 0.45) = 0.26;
uniform float softness : hint_range(0.08, 0.48) = 0.22;

void fragment() {
	vec2 d = abs(UV - vec2(0.5));
	float box_d = max(d.x, d.y);
	float rad_d = length(d);
	float edge = mix(box_d, rad_d, 0.45);
	float mask = 1.0 - smoothstep(inner_rect, min(0.5, inner_rect + softness), edge);
	mask = mask * mask * (3.0 - 2.0 * mask);
	ALBEDO = vec3(mix(1.0, 1.0 - shadow_opacity, clamp(mask, 0.0, 1.0)));
	ALPHA = 1.0;
}
