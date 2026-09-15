// height_fog_card.gdshader — GL Compatibility / mobile-safe, single pass.
// Ground-hugging fog quad: the working substitute for volumetric fog
// (Forward+ only) on BOTH profiles, and the mandated mobile fallback.
// Apply to a horizontal PlaneMesh; instances sit ~0.3 m above ground in
// valleys, creek beds, and the four fog districts. Self-fades near the
// camera (no hard pop when walking through) and at range (hands off to
// the Environment depth fog).
// Uniforms: fog_color #1a2133 canon; alpha = master density.
// Usage (wiring spec W3): district_scene_factory / street_builder place
// 2-6 cards per fog district; OFF on mobile-low (depth fog suffices).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, fog_disabled;

uniform vec4 fog_color : source_color = vec4(0.102, 0.129, 0.2, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.55;
uniform float noise_scale : hint_range(0.5, 12.0) = 3.0;
uniform vec2 drift : hint_range(-0.2, 0.2) = vec2(0.02, 0.01);
uniform float fade_near : hint_range(0.5, 20.0) = 3.0;
uniform float fade_far : hint_range(10.0, 150.0) = 60.0;
uniform float edge_soft : hint_range(0.01, 0.5) = 0.15;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	float edge = smoothstep(0.0, edge_soft, UV.x) * smoothstep(0.0, edge_soft, UV.y)
			* smoothstep(0.0, edge_soft, 1.0 - UV.x) * smoothstep(0.0, edge_soft, 1.0 - UV.y);
	float n = vnoise(UV * noise_scale + TIME * drift);
	float depth = -VERTEX.z;
	float dfade = smoothstep(fade_near * 0.3, fade_near, depth)
			* (1.0 - smoothstep(fade_far * 0.6, fade_far, depth));
	ALBEDO = fog_color.rgb;
	ALPHA = alpha * (0.35 + 0.65 * n) * edge * dfade;
}
