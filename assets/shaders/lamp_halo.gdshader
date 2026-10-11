// lamp_halo.gdshader: GL Compatibility / mobile-safe, single pass.
// A soft brass glow around a lit lamp head, one camera-facing quad per lamp in a MultiMesh (scripts/world/street_props.gd).
// Additive, no depth write, no fog (a fogged additive quad would add the fog colour). The glow is gone inside near_fade so a lamp next to the
// camera never fills the screen, and beyond far_fade where it would be a speck.
// Uniforms:
//   tint       : brass #c9a24a, the style guide's only warm hue
//   strength   : the district's power stage, set from code (DARK 0 ... FULL 1)
//   near_fade  : metres; the halo is full from here outward and fades to nothing at 40% of it
//   far_fade   : metres; the halo fades out between 60% of it and it
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(0.788, 0.635, 0.290, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float peak : hint_range(0.0, 1.0) = 0.45;
uniform float near_fade : hint_range(0.5, 20.0) = 6.0;
uniform float far_fade : hint_range(20.0, 200.0) = 90.0;

varying float fade;

void vertex() {
	// the standard billboard: the model's translation, the camera's rotation
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	float d = length(MODELVIEW_MATRIX[3].xyz);
	fade = smoothstep(near_fade * 0.4, near_fade, d) * (1.0 - smoothstep(far_fade * 0.6, far_fade, d));
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float glow = pow(clamp(1.0 - r, 0.0, 1.0), 2.2);
	ALBEDO = tint.rgb;
	ALPHA = glow * strength * fade * peak;
}
