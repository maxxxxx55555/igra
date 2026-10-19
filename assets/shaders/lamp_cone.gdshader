// lamp_cone.gdshader — GL Compatibility / mobile-safe, single pass, additive, no textures.
// The faint cone of light under a lit streetlamp (scripts/world/lamp_details.gd): one MultiMesh of open cylinders from the lamp head (narrow) to the ground (wide), one draw call for the district. The light is the
// palette's brass-dim (#8a7338), strongest at the head and gone at the ground; the edges melt away where the surface turns edge-on to the eye, so the cone has no outline; no face adds more than max_alpha, so
// two cones that overlap in a view do not burn out to cream; and it is gone when the camera is a few metres from its centre (seen from there the near face is a flat slab of light, and a player standing under
// a lamp is wrapped in it) and again far away (a distant cone is a few pixels of nothing).
// Uniforms:
//   strength : the cone at the power stage of the district (0 in the dark: the lamp is off).
//   max_alpha : the most one face of the cone adds, whatever the strength.
//   fade_near : the distance in metres from the camera to the centre of the cone at which the cone is whole; it is gone at 55 percent of that.
//   fade_far : the distance in metres from the camera over which a far cone disappears.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 tint : source_color = vec4(0.541, 0.451, 0.22, 1.0);
uniform float strength : hint_range(0.0, 8.0) = 0.0;
uniform float max_alpha : hint_range(0.0, 1.0) = 0.4;
uniform float fade_near : hint_range(0.5, 10.0) = 6.0;
uniform float fade_far : hint_range(5.0, 80.0) = 36.0;

varying float v_along;
varying float v_centre;

void vertex() {
	v_along = 0.5 - VERTEX.y;  // the unit cylinder spans y = +0.5 at the lamp head to -0.5 at the ground
	v_centre = length((MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
}

void fragment() {
	float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 1.6);
	float dist = length(VERTEX);
	float distance_fade = smoothstep(fade_near * 0.55, fade_near, v_centre) * (1.0 - smoothstep(fade_far * 0.5, fade_far, dist));
	ALBEDO = tint.rgb;
	ALPHA = min(strength * (1.0 - clamp(v_along, 0.0, 1.0)) * edge * distance_fade, max_alpha);
}
