// dead_grass.gdshader — GL Compatibility / mobile-safe, single pass, alpha scissor.
// The dead grass of the courtyards (scripts/world/dead_grass.gd, the Soviet canon of Session 27): a tuft is two crossed quads (one MultiMesh for the district),
// and the blades are drawn here, five to a quad: thin triangles of straw of different heights that lean a little and sway in the wind.
// Uniforms:
//   straw : the colour of the blades at the root, linear (the tips are lighter).
//   sway  : metres the tips move (0 holds them still: Motion Comfort and Reduce UI Motion).
//   reach : metres from the camera beyond which a tuft is not drawn (its vertices collapse into one point).
shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform vec3 straw = vec3(0.28, 0.24, 0.11);
uniform float sway : hint_range(0.0, 0.3) = 0.08;
uniform float reach : hint_range(5.0, 80.0) = 38.0;

varying float v_seed;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void vertex() {
	v_seed = hash11(MODEL_MATRIX[3].x * 1.7 + MODEL_MATRIX[3].z * 2.3);
	if (length((MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz) > reach) {
		VERTEX = vec3(0.0);
	}
	float top = 1.0 - UV.y;
	float phase = v_seed * 40.0;
	VERTEX.x += (sin(TIME * 1.3 + phase) + 0.5 * sin(TIME * 3.1 + phase * 1.3)) * sway * top * top;
}

void fragment() {
	float x = UV.x * 5.0;
	float i = floor(x) + v_seed * 17.0;
	float up = 1.0 - UV.y;
	float height = 0.45 + 0.55 * hash11(i * 3.7);
	float centre = 0.5 + (hash11(i * 5.3) - 0.5) * 0.5 * up;
	float inside = step(abs(fract(x) - centre), 0.5 * (1.0 - up / height) * 0.9) * step(up, height);
	ALPHA = inside;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALBEDO = straw * (0.7 + 0.6 * up) * (0.8 + 0.4 * hash11(i * 7.1));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
