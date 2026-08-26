// fog_depth.gdshader — GL Compatibility / mobile-safe, single pass.
// Exponential distance fog pulling the world into cold night blue.
// Approximation: mixes ALBEDO toward fog color with distance, so lit surfaces
// keep a hint of warmth up close and drown in cold haze far away.
// Uniforms:
//   fog_color : vec4 source_color — night blue (#1a2133)
//   density   : float — exponential falloff (0.012)
//   start     : float — fog-free radius in meters (5.0)
//   max_mix   : float — ceiling so silhouettes never fully vanish (0.95)
// Usage: assign ShaderMaterial to world geometry (or use as next_pass on a
//        base material). Per-material override of density for interiors.
shader_type spatial;

uniform vec4 fog_color : source_color = vec4(0.102, 0.129, 0.200, 1.0);
uniform float density : hint_range(0.0, 0.2) = 0.012;
uniform float start : hint_range(0.0, 50.0) = 5.0;
uniform float max_mix : hint_range(0.0, 1.0) = 0.95;

varying float v_dist;

void vertex() {
    v_dist = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
}

void fragment() {
    float f = clamp(1.0 - exp(-density * max(v_dist - start, 0.0)), 0.0, max_mix);
    ALBEDO = mix(ALBEDO, fog_color.rgb, f);
}
