// light_cone.gdshader — GL Compatibility / mobile-safe, single pass.
// The cone of light under a lit streetlamp (docs/STYLE_GUIDE.md: one warm key with a volumetric cone): additive, brightest at the lamp,
// gone at the ground, and its silhouette fades where the surface turns edge-on to the eye, so it reads as light in the air and not as a solid wedge.
// tint: the key colour, its alpha the strength by power stage; height: the height of the cone mesh in metres.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.79, 0.635, 0.29, 0.07);
uniform float height = 4.1;

varying float v_top;

void vertex() {
	v_top = clamp(VERTEX.y / height + 0.5, 0.0, 1.0);
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	ALBEDO = tint.rgb;
	ALPHA = tint.a * v_top * v_top * pow(facing, 1.6);
}
