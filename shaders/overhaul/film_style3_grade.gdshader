shader_type canvas_item;

// Unifies 3D streets with main menu lantern art & Reference Style 3:
// Deep cool-charcoal shadows, rich sodium-amber highlights, soft edge vignette, subtle film grain.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float grain_amount : hint_range(0.0, 0.04) = 0.013;
uniform float vignette_strength : hint_range(0.0, 0.55) = 0.28;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.45;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 src = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(src, vec3(0.2126, 0.7152, 0.0722));
	vec3 cool_shadow = vec3(0.87, 0.95, 1.04);
	vec3 warm_amber = vec3(1.08, 0.98, 0.84);
	vec3 col = mix(src, src * mix(cool_shadow, warm_amber, smoothstep(0.10, 0.62, luma)), grade_strength);

	vec2 d = SCREEN_UV - vec2(0.5);
	float vig = 1.0 - smoothstep(0.30, 0.90, length(d)) * vignette_strength;
	col *= vig;

	float g = (hash12(FRAGCOORD.xy + vec2(fract(TIME * 31.0) * 256.0, fract(TIME * 17.0) * 256.0)) - 0.5) * grain_amount;
	col = clamp(col + vec3(g) * smoothstep(0.02, 0.16, luma), 0.0, 1.0);
	COLOR = vec4(col, 1.0);
}
