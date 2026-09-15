// foliage_sway.gdshader — GL Compatibility / mobile-safe, vertex wind.
// Height-weighted wind sway for tree/bush leaves. Per-instance phase from
// the model origin, so the batched TreeLeavesBatched MultiMesh and any
// unbatched trees sway out of sync with zero code changes.
// Uniforms:
//   sway_strength : float — lateral sway amplitude in meters.
//   sway_top      : float — local height at which sway reaches full
//                   strength (tune to the leaf mesh; default fits the
//                   ~1.2 m street-tree crowns).
//   wind_speed/gust_strength : float — breeze + slow gust layer.
// Usage (wiring spec W5): mat_foliage_sway.tres as TreeLeavesBatched
// material_override (replaces the flat StandardMaterial3D).
shader_type spatial;

uniform vec4 leaf_color : source_color = vec4(0.15, 0.45, 0.18, 1.0);
uniform float roughness : hint_range(0.5, 1.0) = 0.9;
uniform float sway_strength : hint_range(0.0, 0.5) = 0.08;
uniform float sway_top : hint_range(0.1, 5.0) = 1.2;
uniform float wind_speed : hint_range(0.0, 6.0) = 1.6;
uniform float gust_strength : hint_range(0.0, 0.5) = 0.05;

void vertex() {
	float phase = MODEL_MATRIX[3].x * 1.7 + MODEL_MATRIX[3].z * 2.3;
	float w = clamp(VERTEX.y / sway_top, 0.0, 1.0);
	w *= w;
	float sway = sin(TIME * wind_speed + phase)
			+ 0.5 * sin(TIME * wind_speed * 2.7 + phase * 1.3);
	float gust = sin(TIME * 0.5 + phase * 0.5) * gust_strength;
	VERTEX.x += (sway * sway_strength + gust) * w;
	VERTEX.z += (sway * sway_strength * 0.7 + gust * 0.6) * w;
}

void fragment() {
	ALBEDO = leaf_color.rgb;
	ROUGHNESS = roughness;
}
