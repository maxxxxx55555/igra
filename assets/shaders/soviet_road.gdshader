// soviet_road.gdshader — GL Compatibility / mobile-safe, single pass, procedural wear over the tile's own texture.
// The street tiles of a district (scripts/world/street_builder.gd): asphalt, the concrete of the sidewalks and the painted
// dashes of the lane marking, in the Soviet canon of Session 27: patched and cracked surface, damp where the road dips,
// flaked paint. The tint is the tile's mean albedo in linear light, so a lamp lights a grey road and a pale dash,
// never a slab (the old marking was a whole 4 m tile at 0.9).
// Uniforms:
//   tint     : the tile's mean albedo, linear.
//   mean_lum : the mean luminance of `tex`, so the texture only varies the tint around its mean (1.0 with no texture).
//   detail   : 0 the plain tile (Low tier), 1 patches, 2 adds hairline cracks, damp patches and chipped paint.
//   paint    : 1 for the lane dashes (chips, no cracks, never damp).
//   damp     : how much of the road reads wet (a lower roughness, a little darker).
//   tint_b, mix_b : a second tint in large patches (the dead grass and bare earth of a courtyard, the ground plane of the skyline); 0 for the street.
shader_type spatial;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint = vec3(0.055, 0.057, 0.063);
uniform float mean_lum = 0.04;
uniform float detail : hint_range(0.0, 2.0) = 2.0;
uniform float paint : hint_range(0.0, 1.0) = 0.0;
uniform float damp : hint_range(0.0, 1.0) = 0.5;
uniform vec3 tint_b = vec3(0.0);
uniform float mix_b : hint_range(0.0, 1.0) = 0.0;

varying vec2 v_xz;

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
	v_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float grain = dot(texture(tex, UV).rgb, vec3(0.3333)) / mean_lum;
	float g = clamp(grain, 0.3, 2.2);
	vec3 c = tint * g;
	float wet = 0.0;
	if (detail > 0.5) {
		c *= 0.78 + 0.5 * vnoise(v_xz * 0.35);
		c = mix(c, tint_b * g, smoothstep(0.45, 0.62, vnoise(v_xz * 0.09 + vec2(21.0, 8.0))) * mix_b);
		if (detail > 1.5) {
			float crack = 1.0 - smoothstep(0.0, 0.009, abs(vnoise(v_xz * 2.6 + vec2(3.0, 9.0)) - 0.5));
			float chips = smoothstep(0.52, 0.62, vnoise(v_xz * 6.0 + vec2(2.0, 5.0)));
			c *= (1.0 - 0.35 * crack * (1.0 - paint)) * (1.0 - 0.5 * chips * paint);
			wet = smoothstep(0.58, 0.76, vnoise(v_xz * 0.21 + vec2(11.0, 4.0))) * damp * (1.0 - paint);
		}
	}
	ALBEDO = c * (1.0 - 0.3 * wet);
	ROUGHNESS = mix(0.92, 0.2, wet);
	SPECULAR = 0.35 + 0.4 * wet;
}
