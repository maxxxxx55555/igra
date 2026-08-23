// flashlight_cone.gdshader — GL Compatibility / mobile-safe, single pass.
// Additive volumetric-look cone mesh for flashlights/streetlight pools.
// Apply to an open cone/truncated-cone mesh with apex at the light source:
// UV.y = 0 at apex, 1 at far end. Unshaded additive; fades along axis and
// softly across the rim; subtle organic flicker.
// Uniforms:
//   beam_color : vec4 source_color — warm brass (#c9a24a)
//   intensity  : float — overall brightness (1.6)
//   axial_pow  : float — how fast beam fades along length, higher = tighter (1.8)
//   edge_soft  : float — 0 hard rim .. 1 very soft rim (0.65)
//   flicker    : float — random flicker amount (0.06)
// Usage: MeshInstance3D(cone) -> ShaderMaterial; blend_add set in render_mode,
//        no extra config needed. Keep mesh outside shadow casters.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 beam_color : source_color = vec4(0.788, 0.635, 0.290, 1.0);
uniform float intensity : hint_range(0.0, 8.0) = 1.6;
uniform float axial_pow : hint_range(0.25, 8.0) = 1.8;
uniform float edge_soft : hint_range(0.0, 1.0) = 0.65;
uniform float flicker : hint_range(0.0, 0.5) = 0.06;

void fragment() {
    float axial = pow(clamp(1.0 - UV.y, 0.0, 1.0), axial_pow);
    float rim = sin(clamp(UV.x, 0.0, 1.0) * 3.141593);
    rim = mix(1.0, rim, clamp(edge_soft, 0.0, 1.0));
    float fl = 1.0 + flicker * (sin(TIME * 11.0) * sin(TIME * 7.3) );
    float a = axial * rim * fl;
    ALBEDO = beam_color.rgb * intensity * a;
}
