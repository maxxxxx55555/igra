shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, fog_disabled;

// Authentic misty downward sodium streetlight cone (replaces giant glowing spheres).

uniform vec3 cone_color : source_color = vec3(0.831, 0.663, 0.306);
uniform float intensity : hint_range(0.01, 0.5) = 0.14;
uniform float fresnel_power : hint_range(1.0, 5.0) = 2.4;
uniform float vertical_fade : hint_range(0.5, 4.0) = 1.8;

void fragment() {
	// UV.y = 0 near lamp fixture, 1 near ground
	float top_soft = smoothstep(0.0, 0.14, UV.y);
	float bottom_fade = pow(clamp(1.0 - UV.y, 0.0, 1.0), vertical_fade);
	float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), fresnel_power);
	float alpha = top_soft * bottom_fade * edge * intensity;
	ALBEDO = cone_color;
	ALPHA = clamp(alpha, 0.0, 0.32);
}
