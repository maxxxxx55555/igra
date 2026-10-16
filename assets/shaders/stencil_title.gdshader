// stencil_title.gdshader — GL Compatibility / mobile-safe, canvas item for a Label.
// The title card of the main menu (V2 of Session 27): the letters are cut across once, through the middle of the capitals, the way a stencil is cut to hold its islands, and the dark outline is cut with them, so the
// backdrop shows through the cut. The cut is measured in the label's own pixels from the middle of its rect, where the text block sits (vertical alignment centre). Two cuts and 3 px (launch 5) read as a strikethrough.
// Uniforms:
//   label_h : the height of the label's rect in px (the script keeps it).
//   cut_px  : the thickness of the cut in px.
shader_type canvas_item;

uniform float label_h = 120.0;
uniform float cut_px = 2.4;

varying vec2 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	float y = v_local.y - label_h * 0.5;
	COLOR.a *= smoothstep(cut_px * 0.5 - 0.5, cut_px * 0.5 + 0.5, abs(y));
}
