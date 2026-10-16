// menu_fog.gdshader — GL Compatibility / mobile-safe, single pass (the menu only).
// The fog and the grain over the backdrop of the main menu (scripts/ui/menu_fog.gd, V2 of Session 27): two banks of fog drifting slowly the other way from each
// other, thicker toward the ground, in the canon fog colour (#1a2133, docs/STYLE_GUIDE.md), and a fine film grain that changes twelve times a second.
// Uniforms:
//   fog_color    : the colour of the fog (the canon one).
//   fog_amount   : the opacity of the thickest bank, 0..1.
//   grain_amount : the opacity of the specks of light and dark, 0..0.2.
//   motion       : 1 lets the fog drift and the grain change, 0 holds both still (Reduce UI Motion).
shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.102, 0.129, 0.2, 1.0);
uniform float fog_amount : hint_range(0.0, 1.0) = 0.16;
uniform float grain_amount : hint_range(0.0, 0.2) = 0.05;
uniform float motion : hint_range(0.0, 1.0) = 1.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	float t = TIME * motion;
	vec2 p = UV * vec2(2.4, 1.3);
	float bank = 0.55 * vnoise(p + vec2(t * 0.012, 0.0)) + 0.45 * vnoise(p * 2.3 + vec2(-t * 0.02, t * 0.004));
	float fog = fog_amount * smoothstep(0.25, 0.85, bank) * (0.3 + 0.7 * smoothstep(0.25, 1.0, UV.y));
	float g = hash12(floor(FRAGCOORD.xy) + floor(t * 12.0) * vec2(17.0, 31.0)) - 0.5;
	float speck = abs(g) * grain_amount * 2.0;
	float a = fog + speck * (1.0 - fog);
	COLOR = vec4((fog_color.rgb * fog + vec3(step(0.0, g) * 0.9) * speck * (1.0 - fog)) / max(a, 0.0001), a);
}
