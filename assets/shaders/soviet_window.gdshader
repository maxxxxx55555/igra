// soviet_window.gdshader — GL Compatibility / mobile-safe, single pass, unshaded, no textures.
// The panes of the skyline ring (scripts/world/skyline.gd), one MultiMesh of quads: the instance colour says what a pane is (dark glass, brass lamplight or bone light) and this shader gives it an inside:
// a frame with a transom and now and then an upright, a curtain drawn over one side of some of the lit panes, the light fading toward the corners, a slow flicker in some of the bone ones (a television),
// a faint sky on the dark glass and, rarely, a crack. Nothing is brighter than the colour of the instance and no colour joins the palette (docs/STYLE_GUIDE.md): the pane is the lamp, the frame and the
// curtain are the dark. The choices of each pane come from a hash of its place, so a district looks the same on every visit.
// Uniforms:
//   interior : 0 the flat pane (the Low tier, and the "before" frame of a pair), 1 the pane with its inside.
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
		float calm = 1.0 / (1.0 + aa * 14.0);  // a far pane is a few pixels: it keeps its average and loses its pattern
		float lit = smoothstep(0.1, 0.22, dot(c, vec3(0.3333)));  // brass and bone panes read 0.3 and more, dark glass 0.03
		vec2 d = abs(UV - 0.5);
		float border = smoothstep(0.43, 0.46, max(d.x, d.y));
		float upright = (1.0 - smoothstep(0.014, 0.034, d.x)) * step(0.4, h2);
		float transom = (1.0 - smoothstep(0.014, 0.034, abs(UV.y - 0.68))) * step(0.2, h3);
		float frame = max(border, max(upright, transom));
		float curtain_w = 0.2 + 0.25 * h2;
		float curtain = step(0.5, h1) * (step(UV.x, curtain_w) * step(h1, 0.75) + step(1.0 - curtain_w, UV.x) * step(0.75, h1));
		float falloff = 1.0 - 0.3 * smoothstep(0.12, 0.55, length(d));
		float tv = 1.0 + 0.07 * sin(TIME * (1.3 + 2.0 * h1) + h3 * 31.0) * step(0.55, h2) * step(0.9, c.b / max(c.r, 0.001));
		vec3 lit_c = c * falloff * tv * (1.0 - 0.8 * curtain) * (1.0 - 0.85 * frame);
		float crack = step(0.97, h3) * (1.0 - smoothstep(0.0, 0.015 + aa, abs((UV.x - 0.5) - (UV.y - 0.5) * 0.7 - 0.06)));
		vec3 dark_c = (c + vec3(0.010, 0.014, 0.022) * (1.0 - UV.y)) * (1.0 - 0.6 * frame) + vec3(0.05) * crack;
		c = mix(c * mix(1.0, 0.82, lit), mix(dark_c, lit_c, lit), calm);
	}
	ALBEDO = c;
}
