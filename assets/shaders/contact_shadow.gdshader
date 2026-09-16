// contact_shadow.gdshader — GL Compatibility / mobile-safe, single pass.
// Soft radial blob decal: grounds props (crates, poles, benches) where
// SSAO is off (mobile) and tightens contact even where SSAO is on.
// Apply to a horizontal QuadMesh/PlaneMesh ~0.02 m above the ground,
// scaled to the prop footprint. fog stays ON so distant blobs melt into
// the depth fog instead of popping.
// Uniforms: strength = master opacity (0 disables); softness = edge falloff.
// Usage (wiring spec W6): street_props/city_decorator stamp one per prop;
// OFF on mobile-low (draw-call budget).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 shadow_color : source_color = vec4(0.02, 0.027, 0.043, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.55;
uniform float softness : hint_range(0.1, 1.0) = 0.45;

void fragment() {
	float d = length((UV - 0.5) * 2.0);
	float a = 1.0 - smoothstep(1.0 - softness - 0.35, 1.0, d);
	ALBEDO = shadow_color.rgb;
	ALPHA = a * strength;
}
