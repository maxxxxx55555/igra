shader_type canvas_item;

// Clean cinematic night grading matched to main menu streetlamp art:
// Deep cool-charcoal shadows, rich sodium-amber pools, soft vignette, ultra-fine grain (no static noise).

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float grain_amount : hint_range(0.0, 0.02) = 0.0045;
uniform float vignette_strength : hint_range(0.0, 0.55) = 0.24;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.42;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 src = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(src, vec3(0.2126, 0.7152, 0.0722));
	vec3 cool_shadow = vec3(0.86, 0.94, 1.04);
	vec3 warm_amber = vec3(1.09, 0.98, 0.84);
	vec3 col = mix(src, src * mix(cool_shadow, warm_amber, smoothstep(0.12, 0.60, luma)), grade_strength);

	vec2 d = SCREEN_UV - vec2(0.5);
	float vig = 1.0 - smoothstep(0.34, 0.92, length(d)) * vignette_strength;
	col *= vig;

	// Apply subtle grain only in midtones (never speckles pure dark shadows)
	float mid_mask = smoothstep(0.06, 0.22, luma) * (1.0 - smoothstep(0.75, 0.98, luma));
	float g = (hash12(FRAGCOORD.xy + vec2(fract(TIME * 29.0) * 192.0, fract(TIME * 17.0) * 192.0)) - 0.5) * grain_amount;
	col = clamp(col + vec3(g) * mid_mask, 0.0, 1.0);
	COLOR = vec4(col, 1.0);
}
