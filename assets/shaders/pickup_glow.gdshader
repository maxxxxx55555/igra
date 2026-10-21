// pickup_glow.gdshader — GL Compatibility / mobile-safe, single pass, additive, no textures.
// The pool of light a pickup throws on the ground in place of a real light (scripts/world/contact_shadows.gd, the "PickupGlow" MultiMesh: a few quads, the nearest pickups that glow).
// The instance colour is the colour of the pickup and its alpha the strength, already faded with the distance; a soft disc, brightest in the middle.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

varying vec4 v_color;

void vertex() {
	v_color = COLOR;
}

void fragment() {
	float pool = 1.0 - smoothstep(0.0, 1.0, length((UV - 0.5) * 2.0));
	ALBEDO = v_color.rgb;
	ALPHA = pool * pool * v_color.a;
}
