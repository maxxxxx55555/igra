// soviet_sign.gdshader — GL Compatibility / mobile-safe, single pass.
// The stencilled signs of a district (scripts/world/soviet_signs.gd): a Russian word painted straight onto the concrete,
// from a baked atlas of the words (white glyphs on clear, one row a word). One quad a sign, one MultiMesh a district;
// the per-instance data says which row, how much of the row the word fills, a seed and the colour of the paint.
// The stencil is the slits that hold the islands of a letter, the age is paint that flaked.
// Uniforms:
//   atlas  : the baked words, rows of equal height from the top.
//   rows   : how many words the atlas holds.
//   detail : 0 clean paint (Low tier draws no signs at all), 1 and 2 add the flaking.
//   lit    : how much of the paint's own glow shows (the power stage of the district): the paint holds the light of the street the way the facade does, so a sign reads where no lamp reaches.
// INSTANCE_CUSTOM: x the row, y the share of the row the word fills (the quad shows just that, centred), z a seed, w the paint (0 bone, 1 faded yellow, 2 faded red).
shader_type spatial;

uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform float rows = 3.0;
uniform float detail : hint_range(0.0, 2.0) = 2.0;
uniform float lit : hint_range(0.0, 1.0) = 1.0;

varying vec4 v_cell;

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
	v_cell = INSTANCE_CUSTOM;
}

void fragment() {
	vec2 uv = vec2((UV.x - 0.5) * v_cell.y + 0.5, (v_cell.x + UV.y) / rows);
	float glyph = texture(atlas, uv).a;
	float slit = smoothstep(0.0, 0.012, abs(UV.y - 0.5) - 0.012) * smoothstep(0.0, 0.012, abs(UV.y - 0.27) - 0.007) * smoothstep(0.0, 0.012, abs(UV.y - 0.73) - 0.007);
	float flaked = 0.0;
	if (detail > 0.5) {
		flaked = smoothstep(0.55, 0.72, vnoise(vec2(UV.x * 22.0, UV.y * 5.0) + v_cell.z * 31.0));
	}
	vec3 paint = vec3(0.50, 0.48, 0.42);
	if (v_cell.w > 1.5) {
		paint = vec3(0.42, 0.10, 0.08);
	} else if (v_cell.w > 0.5) {
		paint = vec3(0.50, 0.40, 0.14);
	}
	vec3 ink = paint * (0.75 + 0.25 * vnoise(vec2(UV.x * 9.0, UV.y * 3.0) + v_cell.z * 7.0));
	ALBEDO = ink;
	EMISSION = ink * 0.9 * lit;
	ALPHA = glyph * slit * (1.0 - 0.85 * flaked);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
