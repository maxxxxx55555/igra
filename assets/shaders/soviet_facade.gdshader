// soviet_facade.gdshader — GL Compatibility / mobile-safe, single pass, no textures.
// Weathered panel-block facades for the skyline ring (docs/STYLE_GUIDE.md, the Soviet canon of Session 27): the seams of
// the concrete panels, a rain stain under every window, ragged patches where the whitewash has flaked off, and rust
// that drips from the cornice. Everything is read from the box itself: the instance scale is the size in metres,
// the instance colour is the facade tint, the instance origin seeds the weathering of that one building, so one
// MultiMesh of blocks and roof boxes is one draw call. The pattern follows the window grid of scripts/world/skyline.gd
// (first window 1.2 m from the left edge of the front face, every 2.2 m; first floor of windows 2.6 m up, every 2.6 m).
// Uniforms:
//   glow   : the cold tint of the district's self-glow, linear; gain: how much of it a block shows at the power stage of its district (a restored district reads lighter). The glow is what carries the pattern at night,
//            and the Filmic toe of the scene's tonemapper keeps anything under about 0.05 linear at the black floor, so the gain is about 1.
//   detail : 0 the plain tinted box (Low tier), 1 seams and stains, 2 adds the flaked patches and the rust.
shader_type spatial;

uniform vec3 glow = vec3(0.06, 0.08, 0.12);
uniform float gain : hint_range(0.0, 3.0) = 1.0;
uniform float detail : hint_range(0.0, 2.0) = 2.0;
uniform vec3 rust = vec3(0.30, 0.17, 0.10);  // linear: what the drip adds is a fraction of it

varying vec3 v_pos;
varying vec3 v_size;
varying vec3 v_normal;
varying vec3 v_tint;
varying float v_seed;

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
	v_seed = hash12(MODEL_MATRIX[3].xz);
}

void fragment() {
	vec3 base = v_tint;
	float keep = 1.0;
	float lift = 1.0;
	float flake = 0.0;
	if (detail > 0.5) {
		float roof = step(0.5, v_normal.y);
		float side = step(0.5, abs(v_normal.x));
		float front = step(0.5, v_normal.z);
		float face_w = mix(v_size.x, v_size.z, side);
		float u = mix(v_pos.x, v_pos.z, side) + 0.5 * face_w;
		float y = v_pos.y + 0.5 * v_size.y;
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
		float exists = step(0.0, col) * step(1.2 + col * 2.2, face_w - 1.0) * step(0.0, win) * step(2.6 * (win + 1.0), v_size.y - 1.4);
		float reach = 0.7 + 1.5 * hash12(vec2(col, win) + v_seed * 91.0);
		float stain = front * exists * (1.0 - smoothstep(0.0, reach, fall)) * (1.0 - smoothstep(0.10, 0.34, to_col));
		// the drips from the cornice, one column in two or three
		float drip_col = floor(u * 1.7);
		float drip = (1.0 - roof) * step(0.58, hash12(vec2(drip_col, v_seed * 53.0))) * (1.0 - smoothstep(0.0, 1.2 + 1.6 * hash12(vec2(drip_col, 7.0)), v_size.y - y));
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
	ALBEDO = base * keep;
	EMISSION = glow * gain * keep * lift;
	// the whitewash keeps a faint sheen that the flaked patches have lost: a lamp shows where the paint is peeling
	ROUGHNESS = 0.7 + 0.3 * flake;
	SPECULAR = 0.25 * (1.0 - flake) * step(0.5, detail);
}
