// soviet_facade.gdshader — GL Compatibility / mobile-safe, single pass (Option B FPP Main-Menu Harmonized).
// Weathered dark night facades: wet dampness near ground, restrained sodium lower bounce,
// deep dark upper silhouettes against night sky — eliminates pale blue cardboard walls.
shader_type spatial;

uniform vec3 glow = vec3(0.5, 0.67, 1.0);
uniform float gain : hint_range(0.0, 3.0) = 0.4;
uniform float detail : hint_range(0.0, 2.0) = 2.0;
uniform sampler2D facade_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D facade_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D facade_roughness : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float tex_scale = 0.34;
uniform vec3 rust = vec3(0.28, 0.16, 0.09);

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
	v_y = MODEL_MATRIX[3].y + v_pos.y;
}

void fragment() {
	vec3 base = v_tint * 0.68;
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
		float to_floor = abs(fract((y - 1.3) / 2.6 + 0.5) - 0.5) * 2.6;
		float to_upright = abs(fract((u - 2.3) / 4.4 + 0.5) - 0.5) * 4.4;
		float seam = max(1.0 - smoothstep(0.012 + aa, 0.05 + aa * 1.5, to_floor), 1.0 - smoothstep(0.012 + aa, 0.05 + aa * 1.5, to_upright));
		seam *= (1.0 - roof) * calm;
		float col = floor((u - 1.2) / 2.2 + 0.5);
		float to_col = abs(u - (1.2 + col * 2.2));
		float win = ceil((y - 1.95) / 2.6);
		float fall = 1.95 + 2.6 * win - y;
		float exists = step(0.0, col) * step(1.2 + col * 2.2, face_w - 1.0) * step(0.0, win) * step(2.6 * (win + 1.0), block_h - 1.4);
		float reach = 0.7 + 1.5 * hash12(vec2(col, win) + v_seed * 91.0);
		float stain = front * exists * (1.0 - smoothstep(0.0, reach, fall)) * (1.0 - smoothstep(0.10, 0.34, to_col));
		float drip_col = floor(u * 1.7);
		float drip = (1.0 - roof) * step(0.58, hash12(vec2(drip_col, v_seed * 53.0))) * (1.0 - smoothstep(0.0, 1.2 + 1.6 * hash12(vec2(drip_col, 7.0)), block_h - y));
		float mottle = 1.0;
		if (detail > 1.5) {
			float streak = vnoise(vec2(u * 9.0, y * 1.4) + v_seed * 17.0);
			mottle = 0.65 + 0.35 * streak;
			float big = vnoise(vec2(u * 0.28, y * 0.22) + v_seed * 37.0);
			flake = smoothstep(0.64, 0.72, big + 0.2 * (streak - 0.5)) * (1.0 - roof);
		}
		keep = (1.0 - 0.46 * seam) * (1.0 - 0.52 * stain * mottle) * (1.0 - 0.28 * drip);
		base += vec3(0.032, 0.034, 0.032) * flake;
		base += rust * drip * 0.08 * (0.5 + 0.5 * mottle);
		lift = 0.82 + 0.35 * flake;
	}
	vec2 tuv = vec2(u, y) * tex_scale;
	vec3 grain = texture(facade_tex, tuv).rgb;
	// Grounded damp skirt darkening near sidewalk (y < 1.6m) + subtle warm streetlamp bounce (y 1..5m)
	float ground_damp = 1.0 - smoothstep(0.0, 1.5, max(0.0, y));
	float lower_warm = (1.0 - smoothstep(1.2, 5.8, max(0.0, y))) * smoothstep(0.0, 0.8, max(0.0, y));
	base *= mix(vec3(1.0), grain * 0.92, step(0.5, detail));
	base *= mix(1.0, 0.58, ground_damp * 0.78);

	// Restrained night self-glow: dark upper silhouettes, subtle warm-cool street gradient (no pale blue boxes)
	float lamp = clamp(1.05 - y * 0.085, 0.22, 0.92);
	vec3 street_tint = mix(glow * 0.34, vec3(0.62, 0.48, 0.24) * 0.38, lower_warm * 0.55);
	ALBEDO = base * keep;
	EMISSION = street_tint * gain * keep * lift * lamp;
	NORMAL_MAP = texture(facade_nrm, tuv).rgb;
	NORMAL_MAP_DEPTH = 0.85 * step(0.5, detail);
	ROUGHNESS = 0.92;
	if (detail > 0.5) {
		float r_tex = clamp(texture(facade_roughness, tuv).r, 0.62, 0.98);
		ROUGHNESS = mix(mix(r_tex, 0.32, ground_damp * 0.55), 0.98, flake);
	}
	SPECULAR = mix(0.26, 0.52, ground_damp) * (1.0 - flake) * step(0.5, detail);
}
