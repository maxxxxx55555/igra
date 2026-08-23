// grain_overlay.gdshader — GL Compatibility / mobile-safe, single pass.
// Fullscreen animated film grain + vignette for the permanent-night mood.
// Uniforms:
//   grain_amount : float — noise amplitude 0.08..0.12 recommended (0.10)
//   grain_scale  : float — pixel size of grain cells (1.0)
//   vignette     : float — corner darkening strength (0.35)
//   vignette_soft: float — falloff width 0..1 (0.45)
// Usage: CanvasLayer -> ColorRect (full rect, mouse_filter ignore)
//        with this ShaderMaterial; reads screen below automatically.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float grain_amount : hint_range(0.0, 0.3) = 0.10;
uniform float grain_scale : hint_range(0.5, 4.0) = 1.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_soft : hint_range(0.05, 1.0) = 0.45;

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7) + TIME);
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void fragment() {
    vec3 col = texture(screen_tex, SCREEN_UV).rgb;
    vec2 gp = floor(FRAGCOORD.xy * grain_scale);
    float g = hash(gp) - 0.5;
    col += g * grain_amount * (0.35 + 0.65 * (1.0 - dot(col, vec3(0.333))));
    vec2 c = SCREEN_UV - 0.5;
    float v = smoothstep(0.25, 0.25 + vignette_soft, length(c));
    col *= 1.0 - vignette * v;
    COLOR = vec4(col, 1.0);
}
