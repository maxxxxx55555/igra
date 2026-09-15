// wet_asphalt.gdshader — GL Compatibility / mobile-safe, single pass.
// Wet-road surface: procedural puddle mask (no new textures), roughness
// variation, wet darkening, and a cheap screen-space reflection that is
// the Compatibility substitute for SSR (SSR is Forward+ only).
// The screen tap uses filter_linear WITHOUT mipmaps: mipmap blur reads
// show renderer-specific artifacts on Compatibility.
// Uniforms:
//   reflection_strength : float — 0 disables the screen tap entirely
//                         (mobile-low), mask + roughness still read wet.
//   wetness             : float — 0 dry .. 1 soaked (drive from weather).
// Usage (wiring spec W5): mat_wet_asphalt.tres on Ground MeshInstance3D
// (or district_grading ground material slot).
shader_type spatial;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec4 dry_color : source_color = vec4(0.075, 0.085, 0.11, 1.0);
uniform vec4 puddle_color : source_color = vec4(0.03, 0.038, 0.055, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.7;
uniform float puddle_scale : hint_range(0.05, 2.0) = 0.35;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.85;
uniform float distort : hint_range(0.0, 0.2) = 0.06;
uniform float roughness_dry : hint_range(0.5, 1.0) = 0.95;

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
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 p = wp.xz * puddle_scale;
	float n = vnoise(p) * 0.65 + vnoise(p * 2.7 + 13.7) * 0.35;
	float puddle = smoothstep(0.75 - wetness * 0.55, 0.85 - wetness * 0.55, n);
	float ripple = vnoise(wp.xz * 3.0 + vec2(TIME * 0.03, TIME * 0.017));
	vec3 N = normalize(NORMAL);
	vec3 V = normalize(VIEW);
	float fres = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), 2.0);
	ALBEDO = mix(dry_color.rgb, puddle_color.rgb, puddle * 0.9);
	ROUGHNESS = mix(roughness_dry, 0.06, puddle);
	if (reflection_strength > 0.001 && puddle > 0.001) {
		vec2 suv = SCREEN_UV + (vec2(ripple, vnoise(wp.xz * 3.0 - TIME * 0.021)) - 0.5) * distort * puddle;
		vec3 refl = texture(screen_tex, clamp(suv, vec2(0.001), vec2(0.999))).rgb;
		EMISSION = refl * puddle * reflection_strength * (0.35 + 0.65 * fres);
	}
}
