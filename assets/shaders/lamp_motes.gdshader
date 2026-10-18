// lamp_motes.gdshader — GL Compatibility / mobile-safe, single pass, additive billboards, no textures.
// The dust that hangs in the cone of a lit streetlamp (scripts/world/lamp_dust.gd): one MultiMesh, one draw call, the whole drift here in the vertex shader (nothing runs on the CPU).
// The instance origin is the mote's resting place under its lamp; the instance colour carries three numbers: r how near the axis of the cone the mote rests (1 on the axis, a mote at the edge is dark),
// g a size jitter and b a phase. The mote wanders a few centimetres on slow sines, twinkles, and is gone with the distance from the camera. The colour is the palette's brass-dim (#8a7338).
// Uniforms:
//   strength : the dust at the power stage of the district (0 in the dark: no lamp is lit).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 tint : source_color = vec4(0.541, 0.451, 0.22, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float size_m : hint_range(0.01, 0.2) = 0.045;
uniform float fade_near : hint_range(1.0, 60.0) = 14.0;
uniform float fade_far : hint_range(2.0, 80.0) = 34.0;

varying float v_light;

void vertex() {
	vec3 rest = MODEL_MATRIX[3].xyz;
	float phase = COLOR.b * 6.2831853;
	vec3 wander = vec3(sin(TIME * 0.31 + phase * 3.0), 0.6 * sin(TIME * 0.23 + phase * 5.0), cos(TIME * 0.27 + phase * 4.0)) * 0.12;
	vec3 at = rest + wander;
	float scale = size_m * (0.7 + 0.6 * COLOR.g);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], vec4(at, 1.0));
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(scale, 0.0, 0.0, 0.0), vec4(0.0, scale, 0.0, 0.0), vec4(0.0, 0.0, scale, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	float dist = length((VIEW_MATRIX * vec4(at, 1.0)).xyz);
	float twinkle = 0.65 + 0.35 * sin(TIME * (0.9 + COLOR.g) + phase * 7.0);
	v_light = COLOR.r * twinkle * (1.0 - smoothstep(fade_near, fade_far, dist)) * strength;
}

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	ALBEDO = tint.rgb;
	ALPHA = (1.0 - smoothstep(0.1, 1.0, r)) * v_light;
}
