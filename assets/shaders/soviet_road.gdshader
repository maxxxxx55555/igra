// soviet_road.gdshader — GL Compatibility / mobile-safe, single pass, procedural wear over the tile's own texture.
// The street tiles of a district (scripts/world/street_builder.gd): asphalt, the concrete of the sidewalks and the painted
// dashes of the lane marking, in the Soviet canon of Session 27: precast concrete slabs with their joints, asphalt with the rectangles of its repairs,
// damp where the road dips, flaked paint. The tint is the tile's mean albedo in linear light, so a lamp lights a grey road and a pale dash,
// never a slab (the old marking was a whole 4 m tile at 0.9).
// Uniforms:
//   tint     : the tile's mean albedo, linear.
//   mean_lum : the mean luminance of `tex`, so the texture only varies the tint around its mean (1.0 with no texture).
//   detail   : 0 the plain tile (Low tier), 1 patches, 2 adds the slab joints or the repair rectangles (`surface`), damp patches and chipped paint.
//   surface  : 1 concrete slabs (a joint every 1.25 m across and 1.5 m along, the rows shifted), 2 asphalt (dark rectangles where it was repaired), 0 neither.
//   paint    : 1 for the lane dashes (chips, never damp).
//   damp     : how much of the road reads wet (darker, and smoother down to 0.6: the style guide keeps every surface matte, nothing is glossy).
//   tint_b, mix_b : a second tint in large patches (the dead grass and bare earth of a courtyard, the ground plane of the skyline); 0 for the street.
shader_type spatial;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint = vec3(0.055, 0.057, 0.063);
uniform float mean_lum = 0.04;
uniform float detail : hint_range(0.0, 2.0) = 2.0;
uniform float paint : hint_range(0.0, 1.0) = 0.0;
uniform float surface : hint_range(0.0, 2.0) = 0.0;
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
		float blotch = vnoise(v_xz * 0.35);
		c *= 0.78 + 0.5 * blotch;
		c = mix(c, tint_b * g, smoothstep(0.45, 0.62, vnoise(v_xz * 0.09 + vec2(21.0, 8.0))) * mix_b);
		if (detail > 1.5) {
			if (surface > 1.5) {
				vec2 cell = floor(v_xz / vec2(3.2, 5.0));
				vec2 inside = fract(v_xz / vec2(3.2, 5.0)) - 0.5 - 0.2 * (vec2(hash12(cell + 3.0), hash12(cell + 5.0)) - 0.5);
				vec2 reach = abs(inside) - (vec2(0.18, 0.2) + 0.12 * vec2(hash12(cell + 7.0), hash12(cell + 13.0)));
				float repaired = step(max(reach.x, reach.y), 0.0) * step(0.86, hash12(cell));
				c *= 1.0 - 0.28 * repaired - 0.2 * repaired * step(-0.012, max(reach.x, reach.y));
			} else if (surface > 0.5) {
				float row = floor(v_xz.y / 1.5);
				float slab = floor((v_xz.x + 1.25 * hash12(vec2(row, 1.0))) / 1.25);
				c *= 0.84 + 0.32 * hash12(vec2(slab, row) + 17.0);  // every slab its own tone: a lit sidewalk is not a grid of equal slabs
				vec2 seam = abs(fract(vec2((v_xz.x + 1.25 * hash12(vec2(row, 1.0))) / 1.25, v_xz.y / 1.5) + 0.5) - 0.5) * vec2(1.25, 1.5);
				float aa = fwidth(v_xz.x) + fwidth(v_xz.y);
				c *= 1.0 - 0.42 * (1.0 - smoothstep(0.008 + aa, 0.03 + aa * 1.5, min(seam.x, seam.y))) / (1.0 + aa * 10.0);
			}
			c *= 1.0 - 0.5 * paint * smoothstep(0.52, 0.62, vnoise(v_xz * 6.0 + vec2(2.0, 5.0)));
			wet = smoothstep(0.58, 0.76, vnoise(v_xz * 0.21 + vec2(11.0, 4.0))) * damp * (1.0 - paint);
		}
	}
	ALBEDO = c * (1.0 - 0.3 * wet);
	ROUGHNESS = mix(0.92, 0.6, wet);
	SPECULAR = 0.35 + 0.2 * wet;
}
