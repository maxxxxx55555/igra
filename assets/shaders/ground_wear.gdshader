// ground_wear.gdshader — GL Compatibility / mobile-safe, single pass, alpha, no textures.
// The cracks in the pavement at the foot of a streetlamp (scripts/world/lamp_dust.gd): a flat quad on the ground carries a few dark lines that run where a noise crosses its middle value, in part of the
// quad only and fading to nothing at its edge, so the cracks join the slab under them. The colour is the palette's bg-deep (#0c1016): matte, dark, no highlight. The seed is the quad's place.
// Uniforms:
//   strength : the opacity of the darkest crack.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 tint : source_color = vec4(0.047, 0.063, 0.086, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.6;

varying vec2 v_seed;

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

void vertex() {
	v_seed = MODEL_MATRIX[3].xz * 0.173;
}

void fragment() {
	float edge = 1.0 - smoothstep(0.55, 1.0, length((UV - 0.5) * 2.0));
	vec2 q = UV * 6.0 + v_seed;
	float aa = fwidth(q.x) + fwidth(q.y);
	float line_a = 1.0 - smoothstep(0.0, 0.035 + aa * 0.5, abs(vnoise(q) - 0.5));
	float line_b = 1.0 - smoothstep(0.0, 0.025 + aa * 0.5, abs(vnoise(q * 2.3 + 7.1) - 0.5));
	float part = smoothstep(0.35, 0.65, vnoise(UV * 2.0 + v_seed * 1.7));
	ALBEDO = tint.rgb;
	ALPHA = max(line_a, 0.7 * line_b) * part * edge * strength;
}
