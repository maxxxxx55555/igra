// stencil_title.gdshader — GL Compatibility / mobile-safe, canvas item for a Label.
// The title card of the main menu (V2 of Session 27): the letters are cut across twice, the way a stencil is cut to hold its islands, and the dark outline is cut with them, so the backdrop shows through
// the cuts. The cuts are measured in the label's own pixels from the middle of its rect, where the text block sits (vertical alignment centre), so they follow the font size and the locale.
// Uniforms:
//   label_h : the height of the label's rect in px (the script keeps it).
//   font_px : the font size in px; the cuts lie at 18 % above and 16 % below the middle of it.
//   cut_px  : the thickness of a cut in px.
shader_type canvas_item;

uniform float label_h = 120.0;
uniform float font_px = 44.0;
uniform float cut_px = 3.0;

varying vec2 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	float y = v_local.y - label_h * 0.5;
	float to_cut = min(abs(y + font_px * 0.18), abs(y - font_px * 0.16));
	COLOR.a *= smoothstep(cut_px * 0.5 - 0.5, cut_px * 0.5 + 0.5, to_cut);
}
