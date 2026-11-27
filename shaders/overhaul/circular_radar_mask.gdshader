shader_type canvas_item;

// Clips any Control/TextureRect minimap cleanly into a Reference Style 3 circular radar
// with smooth anti-aliased edge, subtle inner vignette, and weathered bronze outer bezel.

uniform vec4 rim_color : source_color = vec4(0.353, 0.290, 0.165, 0.92);
uniform vec4 inner_ring_color : source_color = vec4(0.831, 0.663, 0.306, 0.22);
uniform float rim_width : hint_range(0.005, 0.08) = 0.022;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float dist = length(p);
	if (dist > 0.5) {
		discard;
	}
	vec4 src = texture(TEXTURE, UV) * COLOR;
	// Subtle radial depth darkening toward radar edge
	float vig = 1.0 - smoothstep(0.28, 0.49, dist) * 0.42;
	vec3 col = src.rgb * vig;

	// Subtle inner radar range ring at r=0.25
	float mid_ring = smoothstep(0.008, 0.0, abs(dist - 0.25));
	col = mix(col, inner_ring_color.rgb, mid_ring * inner_ring_color.a);

	// Outer weathered bronze bezel
	float outer_rim = smoothstep(0.5 - rim_width - 0.008, 0.5 - rim_width, dist);
	col = mix(col, rim_color.rgb, outer_rim * rim_color.a);

	float aa = 1.0 - smoothstep(0.490, 0.500, dist);
	COLOR = vec4(col, src.a * aa);
}
