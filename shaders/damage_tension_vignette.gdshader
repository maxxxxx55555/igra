shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec3 ember_color : source_color = vec3(0.66, 0.19, 0.14); // #a83b2e / #c0392b canon ember
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.5, 6.0) = 2.4;
uniform float inner_radius : hint_range(0.35, 0.85) = 0.56;
uniform float outer_radius : hint_range(0.75, 1.35) = 1.08;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 centered = (UV - vec2(0.5)) * vec2(1.0, 0.92);
	float dist = length(centered) * 1.4142;

	// Organic radial falloff — strictly zero rectangular edge line
	float radial = smoothstep(inner_radius, outer_radius, dist);
	radial = radial * radial;

	float pulse = 0.84 + 0.16 * sin(TIME * pulse_speed);
	float grain = 0.92 + 0.08 * hash21(floor(FRAGCOORD.xy * 0.5) + floor(TIME * 12.0));

	float alpha = clamp(radial * intensity * pulse * grain * 0.62, 0.0, 0.65);
	COLOR = vec4(ember_color, alpha);
}
