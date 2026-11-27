shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform vec3 shadow_tint : source_color = vec3(0.024, 0.059, 0.075);   // #060f13
uniform vec3 sodium_key : source_color = vec3(0.831, 0.663, 0.306);    // #d4a94e
uniform vec3 highlight_cap : source_color = vec3(0.910, 0.851, 0.690); // #e8d9b0

uniform float grade_strength : hint_range(0.0, 0.70) = 0.52;
uniform float halation_strength : hint_range(0.0, 0.35) = 0.16;
uniform float halation_threshold : hint_range(0.45, 0.90) = 0.62;
uniform float vignette_strength : hint_range(0.0, 0.40) = 0.24;
uniform float grain_strength : hint_range(0.0, 0.04) = 0.016;
uniform float contrast_lift : hint_range(0.90, 1.18) = 1.06;
// The pivot of the S-curve. It used to sit at 0.5, which is far above anything a
// night street renders: every lit surface landed below the pivot and the curve
// only pushed it further down, so the sodium pools and the wet asphalt ended up
// on the same gray. A low pivot separates the mid-tones (the lamps, the road,
// the lit facades) while the black floor still holds the frame's deep end.
uniform float mid_pivot : hint_range(0.05, 0.50) = 0.22;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 sample_amber_halation(vec2 uv, vec2 px) {
	vec3 acc = vec3(0.0);
	// Two diagonal taps carry the same warm bloom as the old four-tap cross:
	// full-screen texture fetches were the largest post cost in the ablation.
	const vec2 offsets[2] = vec2[2](
		vec2(2.0, 1.0),
		vec2(-2.0, -1.0)
	);
	for (int i = 0; i < 2; i++) {
		vec3 s = texture(screen_texture, clamp(uv + offsets[i] * px, vec2(0.001), vec2(0.999))).rgb;
		float lum = dot(s, vec3(0.2126, 0.7152, 0.0722));
		float warmth = clamp(s.r - s.b, 0.0, 1.0);
		float mask = smoothstep(halation_threshold, 0.96, lum) * smoothstep(0.06, 0.32, warmth);
		acc += s * mask;
	}
	return (acc * 0.5) * sodium_key;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_texture, uv).rgb;
	float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));

	// Split-tone: deepen cold blue-teal shadows, preserve warm sodium pools
	float shadow_w = smoothstep(0.42, 0.04, lum);
	float high_w = smoothstep(0.38, 0.88, lum);
	vec3 graded = mix(col, max(col, shadow_tint) * (0.86 + 0.14 * shadow_tint * 4.0), shadow_w * grade_strength * 0.65);
	graded = mix(graded, graded * mix(vec3(1.0), sodium_key * 1.18, 0.35), high_w * grade_strength * 0.45);

	// Selective sodium-only halation (zero cold/neon glow spam)
	vec3 halo = sample_amber_halation(uv, SCREEN_PIXEL_SIZE * 2.5);
	graded += halo * halation_strength;

	// S-curve micro-contrast around the low pivot, without crushing blacks or
	// clipping to #ffffff
	graded = (graded - mid_pivot) * contrast_lift + mid_pivot;
	graded = min(graded, highlight_cap);
	graded = max(graded, vec3(0.063)); // >= 16/255 purity floor

	// Subtle organic film grain (stronger in mid-shadows, restrained in pure highlights)
	float n = hash12(floor(FRAGCOORD.xy) + fract(TIME * 24.0) * 100.0) - 0.5;
	graded += n * grain_strength * (1.0 - high_w * 0.5);

	// Soft edge vignette
	vec2 centered = uv * 2.0 - 1.0;
	float vig = clamp(dot(centered, centered) * 0.5, 0.0, 1.0);
	graded *= (1.0 - vig * vignette_strength);

	COLOR = vec4(clamp(graded, vec3(0.063), vec3(0.941)), 1.0);
}
