shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.79, 0.63, 0.29, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float radius = length(UV * 2.0 - 1.0);
	if (radius >= 0.94 || strength <= 0.0) {
		discard;
	}
	float falloff = 1.0 - smoothstep(0.0, 0.94, radius);
	ALBEDO = tint.rgb * strength * falloff * falloff;
	ALPHA = falloff;
}
