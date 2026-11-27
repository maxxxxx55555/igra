shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, fog_disabled;

// Restrained misty sodium-amber downward cone matching main menu streetlamp art.

uniform vec3 cone_color : source_color = vec3(0.831, 0.663, 0.306);
uniform float intensity : hint_range(0.01, 0.45) = 0.13;
uniform float fresnel_power : hint_range(1.0, 5.0) = 2.5;
uniform float vertical_fade : hint_range(0.5, 4.0) = 1.9;

void fragment() {
	float top_soft = smoothstep(0.0, 0.14, UV.y);
	float bot_fade = pow(clamp(1.0 - UV.y, 0.0, 1.0), vertical_fade);
	float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), fresnel_power);
	ALBEDO = cone_color;
	ALPHA = clamp(top_soft * bot_fade * edge * intensity, 0.0, 0.30);
}
