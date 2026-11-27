shader_type canvas_item;

// Subtle cinematic grading matching 01_main_menu_ru.png:
// Deep blue-slate shadows, warm amber highlights, gentle edge vignette, micro grain.
// Never lifts blacks into flat gray mud.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float grain_amount : hint_range(0.0, 0.05) = 0.016;
uniform float vignette_strength : hint_range(0.0, 0.6) = 0.28;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.45;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 src = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(src, vec3(0.2126, 0.7152, 0.0722));

	// Split-tone: cool slate shadows (#0a151c) + warm sodium highlights (#d4a94e)
	vec3 shadow_tint = vec3(0.86, 0.96, 1.06);
	vec3 high_tint = vec3(1.06, 0.99, 0.88);
	vec3 graded = src * mix(shadow_tint, high_tint, smoothstep(0.12, 0.65, luma));
	vec3 col = mix(src, graded, grade_strength);

	// Gentle cinematic S-curve preserving dark shadow depth without crushing midtones
	col = clamp(col * (0.98 + 0.06 * smoothstep(0.08, 0.55, luma)), 0.0, 1.0);

	// Edge vignette (darkens corners cleanly, never adds gray lift)
	vec2 d = SCREEN_UV - vec2(0.5);
	float vig = 1.0 - smoothstep(0.32, 0.88, length(d)) * vignette_strength;
	col *= vig;
	// A soft toe preserves separation between the slate walls and black sky.
	col = pow(max(col, vec3(0.0)), vec3(0.65)) * 0.96;
	col /= vec3(1.0) + 1.65 * col;

	// Subtle animated micro film grain
	float g = (hash12(FRAGCOORD.xy + vec2(fract(TIME * 37.0) * 256.0, fract(TIME * 19.0) * 256.0)) - 0.5) * grain_amount;
	col = clamp(col + vec3(g) * smoothstep(0.02, 0.18, luma), 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
