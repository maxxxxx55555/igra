// window_halo.gdshader — GL Compatibility / mobile-safe, single pass, additive, no textures.
// The faint glow that a lit pane throws on the wall round it (scripts/world/skyline.gd, the "WindowHalos" MultiMesh: one quad of `scale` times the pane at the place of every pane, lit with it).
// The instance colour is the colour of the lamp behind the glass (black for a dark pane, which adds nothing); the pane itself is left out of the glow, so the glass keeps its own value and
// the light falls only on the concrete round it. Only the palette's own warm light, and no brighter than a quarter of it.
// Uniforms:
//   scale    : the size of the quad over the size of the pane (the pane fills the middle 1 / scale of it).
//   strength : the glow at the power stage of the district.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform float scale : hint_range(1.2, 4.0) = 2.2;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

varying vec3 v_color;

void vertex() {
	v_color = COLOR.rgb;
}

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	vec2 pane = abs(q) * scale;  // 1 on the edge of the pane
	float outside = smoothstep(0.9, 1.15, max(pane.x, pane.y));
	float glow = 1.0 - smoothstep(0.0, 1.0, length(q));
	ALBEDO = v_color;
	ALPHA = glow * glow * outside * strength * 0.25;
}
