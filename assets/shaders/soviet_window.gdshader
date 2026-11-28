// soviet_window.gdshader — GL Compatibility / mobile-safe, single pass, unshaded (Ref #3 Moody Remaster).
// Replaces glaring flat LEGO-yellow window stickers with recessed, dusty, atmospheric night panes:
// deep dark mullions, curtain silhouettes, muted warm amber tungsten interior depth, and dark reflective glass.
shader_type spatial;
render_mode unshaded;

uniform float interior : hint_range(0.0, 1.0) = 1.0;

varying vec4 v_color;
varying vec2 v_seed;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	v_color = COLOR;
	v_seed = MODEL_MATRIX[3].xz * 0.37 + vec2(MODEL_MATRIX[3].y * 1.71, MODEL_MATRIX[3].y * 0.53);
}

void fragment() {
	vec3 c = v_color.rgb;
	if (interior > 0.5) {
		float h1 = hash12(v_seed);
		float h2 = hash12(v_seed + 17.31);
		float h3 = hash12(v_seed - 41.7);
		float aa = fwidth(UV.x) + fwidth(UV.y);
		float calm = 1.0 / (1.0 + aa * 14.0);
		float lit = smoothstep(0.10, 0.22, dot(c, vec3(0.3333)));

		// Deep architectural frame + transom + vertical sash bar
		vec2 d = abs(UV - 0.5);
		float border = smoothstep(0.41, 0.45, max(d.x, d.y));
		float upright = (1.0 - smoothstep(0.016, 0.036, d.x)) * step(0.25, h2);
		float transom = (1.0 - smoothstep(0.016, 0.036, abs(UV.y - 0.66))) * step(0.15, h3);
		float frame = max(border, max(upright, transom));

		// Curtains & dusty window grime break up flat solid rectangles
		float curtain_w = 0.22 + 0.28 * h2;
		float curtain = step(0.38, h1) * (step(UV.x, curtain_w) * step(h1, 0.70) + step(1.0 - curtain_w, UV.x) * step(0.70, h1));
		float grime = 0.72 + 0.28 * hash12(floor(UV * 18.0) + v_seed * 11.0);
		float falloff = 1.0 - 0.55 * smoothstep(0.08, 0.52, length(d));
		float vertical_grad = mix(0.62, 1.05, smoothstep(0.0, 0.85, 1.0 - UV.y));

		// Tame blinding white/yellow glow into restrained moody tungsten amber (Ref #3 + Main Menu!)
		vec3 warm_tungsten = mix(c, vec3(0.72, 0.50, 0.22), 0.48);
		float dim_var = 0.36 + 0.36 * h3;
		float tv = 1.0 + 0.05 * sin(TIME * (1.2 + 1.8 * h1) + h3 * 29.0) * step(0.65, h2);
		vec3 lit_c = warm_tungsten * dim_var * falloff * vertical_grad * grime * tv * (1.0 - 0.78 * curtain) * (1.0 - 0.88 * frame);

		// Dark unlit glass reflects cold misty night sky softly instead of pure black stickers
		vec3 dark_glass = mix(vec3(0.018, 0.028, 0.034), vec3(0.045, 0.062, 0.070), smoothstep(0.15, 0.90, 1.0 - UV.y)) * (1.0 - 0.75 * frame);
		vec3 shaped = mix(dark_glass, lit_c, lit);
		ALBEDO = mix(c * 0.42, shaped, calm);
	} else {
		ALBEDO = c * 0.42;
	}
}
