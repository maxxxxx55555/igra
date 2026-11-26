// Save to: shaders/sodium_cinematic_grade.gdshader
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.55;
uniform float vignette_strength : hint_range(0.0, 0.8) = 0.26;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.020;

const vec3 SHADOW_TINT = vec3(0.024, 0.059, 0.075);   // #060f13
const vec3 SODIUM_TINT = vec3(0.831, 0.663, 0.306);   // #d4a94e

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	vec3 col = src.rgb;

	// Filmic gentle S-curve preserving deep teal shadow detail & warm highlights
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	vec3 split_tint = mix(SHADOW_TINT * 2.4 + vec3(0.76), mix(vec3(1.0), SODIUM_TINT * 1.18, smoothstep(0.42, 0.92, luma)), smoothstep(0.04, 0.55, luma));
	vec3 graded = col * split_tint;
	graded = clamp((graded * (2.51 * graded + 0.03)) / (graded * (2.43 * graded + 0.59) + 0.14), 0.0, 1.0);
	col = mix(col, graded, grade_strength);

	// Soft atmospheric vignette (keeps focal streetlight crisp)
	vec2 centered = SCREEN_UV - vec2(0.5);
	float vig = smoothstep(0.86, 0.24, dot(centered, centered) * 1.55);
	col *= mix(1.0 - vignette_strength, 1.0, vig);

	// Fine organic film grain (mobile-safe, zero loop)
	float n = hash12(floor(FRAGCOORD.xy) + vec2(fract(TIME * 17.3) * 128.0, fract(TIME * 31.7) * 128.0)) - 0.5;
	col += vec3(n * grain_strength);

	COLOR = vec4(clamp(col, 0.0, 1.0), src.a);
}
