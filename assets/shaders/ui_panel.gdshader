// ui_panel.gdshader — GL Compatibility / mobile-safe, single pass.
// Chamfered panel with brass-family border and baked-in film grain.
// Matches assets/textures/ui tooltip_panel / inventory_slot language.
// Uniforms:
//   panel_color  : vec4 source_color — fill (#141b24)
//   border_color : vec4 source_color — frame (#2a3340 or brass accent)
//   rect_px      : vec2 — control size in pixels (set from code/theme once)
//   chamfer_px   : float — corner cut size (8.0)
//   border_px    : float — frame thickness (2.0)
//   grain_amount : float — subtle texture (0.03)
// Usage: Panel/ColorRect -> ShaderMaterial;
//        material.set_shader_parameter("rect_px", size) on resize.
shader_type canvas_item;

uniform vec4 panel_color : source_color = vec4(0.078, 0.106, 0.141, 0.93);
uniform vec4 border_color : source_color = vec4(0.165, 0.200, 0.251, 1.0);
uniform vec2 rect_px = vec2(256.0, 128.0);
uniform float chamfer_px : hint_range(0.0, 32.0) = 8.0;
uniform float border_px : hint_range(0.0, 8.0) = 2.0;
uniform float grain_amount : hint_range(0.0, 0.12) = 0.03;

float sdf_chamfer_box(vec2 p, vec2 b, float c) {
    vec2 d = abs(p) - b;
    float box = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    float diag = (abs(p.x) + abs(p.y) - (b.x + b.y - c)) * 0.70710678;
    return max(box, diag);
}

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 p = (UV - 0.5) * rect_px;
    vec2 b = rect_px * 0.5 - 1.0;
    float d_outer = sdf_chamfer_box(p, b, chamfer_px);
    float d_inner = sdf_chamfer_box(p, b - vec2(border_px), max(chamfer_px - border_px, 0.0));
    float aa = fwidth(d_outer) + 0.0001;
    float inside = 1.0 - smoothstep(-aa, aa, d_inner);
    float frame = (1.0 - smoothstep(-aa, aa, d_outer)) - inside;
    float g = (hash(floor(FRAGCOORD.xy)) - 0.5) * grain_amount;
    vec3 col = panel_color.rgb * (1.0 + g) * inside + border_color.rgb * frame;
    float a = clamp(frame + inside * panel_color.a, 0.0, 1.0);
    COLOR = vec4(col, a);
}
