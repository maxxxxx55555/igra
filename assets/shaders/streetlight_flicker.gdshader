// streetlight_flicker.gdshader — GL Compatibility / mobile-safe, single pass.
// Emissive lamp-head material for streetlights (batched MultiMesh AND
// per-instance MeshInstance3D paths). Flicker curve mirrors
// scripts/world/streetlight_3d.gd::_process (12 Hz sway + rare dropouts)
// so the lamp mesh and its SpotLight/OmniLight agree visually.
// Per-lamp phase comes from a world-position hash: zero code changes,
// works for batched and unbatched lamps alike.
// Uniforms:
//   lit            : float — district lamp state 0 (DARK) .. 1 (lit).
//                    Tween 0->1 on restore for the turn-on ramp.
//   hum_level      : float — 0..1 live level of the Hum audio bus
//                    (local agent drives from AudioServer bus peak;
//                    1.0 = full shimmer, static fallback on mobile-low).
//   energy_mult    : float — HDR push so lit lamps cross the glow
//                    threshold (1.6 = live lamp_mat emission energy).
// Usage (wiring spec W4): assign mat_lamp_flicker.tres as
// StreetlightLampsBatched material_override + streetlight_3d Lamp material.
shader_type spatial;
render_mode unshaded;

uniform vec4 lit_color : source_color = vec4(1.0, 0.82, 0.48, 1.0);
uniform vec4 off_color : source_color = vec4(0.10, 0.085, 0.06, 1.0);
uniform float lit : hint_range(0.0, 1.0) = 1.0;
uniform float hum_level : hint_range(0.0, 1.0) = 1.0;
uniform float energy_mult : hint_range(0.0, 4.0) = 1.6;
uniform float flicker_speed : hint_range(1.0, 30.0) = 12.0;
uniform float flicker_depth : hint_range(0.0, 0.5) = 0.15;
uniform float dropout_threshold : hint_range(0.8, 1.0) = 0.96;
uniform float dropout_amount : hint_range(0.0, 1.0) = 0.2;
uniform float hum_shimmer : hint_range(0.0, 0.1) = 0.02;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

void fragment() {
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = hash13(floor(wp / 0.5)) * 6.2831853;
	float base = 0.85 + sin(TIME * flicker_speed + phase) * flicker_depth;
	if (sin(TIME * 37.0 + phase * 7.0) > dropout_threshold) {
		base = dropout_amount;
	}
	base += hum_level * hum_shimmer * sin(TIME * 97.0 + phase * 3.0);
	base = clamp(base, 0.0, 1.4);
	vec3 col = mix(off_color.rgb, lit_color.rgb * base * energy_mult, clamp(lit, 0.0, 1.0));
	ALBEDO = col;
}
