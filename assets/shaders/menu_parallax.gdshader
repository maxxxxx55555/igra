// menu_parallax.gdshader — GL Compatibility / mobile-safe, single pass.
// Subtle menu-background parallax for the (flat) menu screens: a slow
// idle drift plus a pointer-driven offset. Apply to a full-rect TextureRect
// holding district loading art (assets/textures/loading/*_loading.png);
// zoom hides the sampling edges.
// Uniforms:
//   parallax : vec2 — pointer offset -0.5..0.5 (local agent drives from
//              mouse position or touch drag; 0,0 = centered).
//   strength : float — max UV shift (0.03 ≈ 30 px at 1080p — subtle).
// Usage (wiring spec W8): main_menu/menu/credits/stats backgrounds;
// mobile-low keeps drift, drops pointer tracking (strength * 0.4).
shader_type canvas_item;

uniform vec2 parallax = vec2(0.0, 0.0);
uniform float strength : hint_range(0.0, 0.1) = 0.03;
uniform float zoom : hint_range(1.0, 1.3) = 1.06;
uniform float drift_amount : hint_range(0.0, 0.02) = 0.004;

void fragment() {
	vec2 uv = (UV - 0.5) / zoom + 0.5;
	uv += parallax * strength;
	uv += vec2(sin(TIME * 0.3), cos(TIME * 0.23)) * drift_amount;
	COLOR = texture(TEXTURE, clamp(uv, vec2(0.001), vec2(0.999)));
}
