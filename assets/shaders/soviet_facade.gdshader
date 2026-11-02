// soviet_facade.gdshader — GL Compatibility / mobile-safe, single pass, one texture.
// Weathered panel-block facades for the skyline ring (docs/STYLE_GUIDE.md, the Soviet canon of Session 27): the seams of
// the concrete panels, a rain stain under every window, ragged patches where the whitewash has flaked off, and rust that
// drips from the cornice. The front of a block is not one box: scripts/world/skyline.gd builds it as piers and bands around
// the window openings, and every piece carries its own block in its instance data — x the width of the facade the panel grid
// is measured against, y its height, z how far the piece sits along that width, and w the seed of that one building's
// weathering. So the seam of a lintel meets the seam of the wall behind it and the stain runs under the window it belongs to,
// while the whole ring stays one draw call. The pattern follows the window grid of scripts/world/skyline.gd (first window
// 1.2 m from the left edge of the front face, every 2.2 m; first floor of windows 2.6 m up, every 2.6 m).
// Uniforms:
//   glow   : the hue of the district's self-glow (half of it: a concrete wall, not coloured glass), scaled so that its mean channel is 1; gain: the emission of that channel at the power stage of the district (a restored district reads lighter). The glow carries the
//            pattern at night. The wall line of tools/qa_sim/density_frames reads the median wall level over the black floor of the grade: +8 at a gain of 0.20, +20 at 0.26, +40 at 0.34 in the suburbs, a steeply convex response,
//            so seams and stains of 40 % in emission read as much more in light, and the gain is under 1.
//   detail : 0 the plain tinted box (Low tier), 1 seams and stains, 2 adds the flaked patches and the rust.
shader_type spatial;

uniform vec3 glow = vec3(0.5, 0.67, 1.0);
uniform float gain : hint_range(0.0, 3.0) = 0.4;
uniform float detail : hint_range(0.0, 2.0) = 2.0;
uniform sampler2D facade_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D facade_nrm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float tex_scale = 0.34;
uniform vec3 rust = vec3(0.30, 0.17, 0.10);  // linear: what the drip adds is a fraction of it

varying vec3 v_pos;
varying vec3 v_size;
varying vec3 v_normal;
varying vec3 v_tint;
varying vec3 v_block;
varying float v_seed;
varying float v_y;

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
	v_size = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	v_pos = VERTEX * v_size;
	v_normal = NORMAL;
	v_tint = COLOR.rgb;
	v_block = INSTANCE_CUSTOM.xyz;
	v_seed = INSTANCE_CUSTOM.w;
	if (v_seed <= 0.0) {
		v_seed = hash12(MODEL_MATRIX[3].xz);
	}
	// the height of this point above the ground of its own block: the ring turns are about the upright axis, so the vertical
	// needs no unrotating, and every piece of a block measures from the same sill
	v_y = MODEL_MATRIX[3].y + v_pos.y;
}

void fragment() {
	vec3 base = v_tint;
	float keep = 1.0;
	float lift = 1.0;
	float flake = 0.0;
	float side_face = step(0.5, abs(v_normal.x));
	float face_w = mix(v_size.x, v_block.x, step(0.001, v_block.x));
	float block_h = mix(v_size.y, v_block.y, step(0.001, v_block.y));
	float u = mix(v_pos.x + v_block.z, v_pos.z, side_face) + 0.5 * face_w;
	float y = v_y;
	if (detail > 0.5) {
		float roof = step(0.5, v_normal.y);
		float front = step(0.5, v_normal.z);
		float aa = fwidth(y) + fwidth(u) + 0.0001;
		float calm = 1.0 / (1.0 + aa * 14.0);
		// the seams of the panels: a floor seam between two rows of windows, an upright seam between every second window
		float to_floor = abs(fract((y - 1.3) / 2.6 + 0.5) - 0.5) * 2.6;
		float to_upright = abs(fract((u - 2.3) / 4.4 + 0.5) - 0.5) * 4.4;
		float seam = max(1.0 - smoothstep(0.012 + aa, 0.05 + aa * 1.5, to_floor), 1.0 - smoothstep(0.012 + aa, 0.05 + aa * 1.5, to_upright));
		seam *= (1.0 - roof) * calm;
		// the rain stain under each window of the front face, as long as the window above it exists
		float col = floor((u - 1.2) / 2.2 + 0.5);
		float to_col = abs(u - (1.2 + col * 2.2));
		float win = ceil((y - 1.95) / 2.6);
		float fall = 1.95 + 2.6 * win - y;
		float exists = step(0.0, col) * step(1.2 + col * 2.2, face_w - 1.0) * step(0.0, win) * step(2.6 * (win + 1.0), block_h - 1.4);
		float reach = 0.7 + 1.5 * hash12(vec2(col, win) + v_seed * 91.0);
		float stain = front * exists * (1.0 - smoothstep(0.0, reach, fall)) * (1.0 - smoothstep(0.10, 0.34, to_col));
		// the drips from the cornice, one column in two or three
		float drip_col = floor(u * 1.7);
		float drip = (1.0 - roof) * step(0.58, hash12(vec2(drip_col, v_seed * 53.0))) * (1.0 - smoothstep(0.0, 1.2 + 1.6 * hash12(vec2(drip_col, 7.0)), block_h - y));
		float mottle = 1.0;
		if (detail > 1.5) {
			float streak = vnoise(vec2(u * 9.0, y * 1.4) + v_seed * 17.0);
			mottle = 0.65 + 0.35 * streak;
			float big = vnoise(vec2(u * 0.28, y * 0.22) + v_seed * 37.0);
			flake = smoothstep(0.64, 0.72, big + 0.2 * (streak - 0.5)) * (1.0 - roof);
		}
		keep = (1.0 - 0.42 * seam) * (1.0 - 0.5 * stain * mottle) * (1.0 - 0.25 * drip);
		base += vec3(0.05, 0.052, 0.05) * flake;
		base += rust * drip * 0.09 * (0.5 + 0.5 * mottle);
		lift = 0.85 + 0.5 * flake;
	}
	// the grain of the concrete, read along the same grid so a pier and the wall behind it carry the same stone
	vec2 tuv = vec2(u, y) * tex_scale;
	vec3 grain = texture(facade_tex, tuv).rgb;
	base *= mix(vec3(1.0), grain * 1.35, step(0.5, detail));
	// the streetlights reach nine metres up the wall and no further: the ground storeys take the light, the top of a block is
	// a dark mass against the sky. A flat glow over the whole facade is what makes a night city read as a painted box.
	float lamp = clamp(1.32 - y * 0.072, 0.46, 1.12);
	ALBEDO = base * keep;
	EMISSION = glow * gain * keep * lift * lamp;
	// the whitewash keeps a faint sheen that the flaked patches have lost: a lamp shows where the paint is peeling
	NORMAL_MAP = texture(facade_nrm, tuv).rgb;
	NORMAL_MAP_DEPTH = 0.7 * step(0.5, detail);
	ROUGHNESS = 0.7 + 0.3 * flake;
	SPECULAR = 0.25 * (1.0 - flake) * step(0.5, detail);
}
