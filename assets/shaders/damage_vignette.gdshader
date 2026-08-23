// damage_vignette.gdshader — GL Compatibility / mobile-safe, single pass.
// Ember-red heartbeat vignette when the player is hurt. Pulses at 60 bpm;
// script drives `strength` 0..1 and fades it out over ~3 s (lerp in _process).
// Uniforms:
//   strength     : float — current damage feedback 0..1 (drive from code)
//   pulse_bpm    : float — heartbeat rate (60.0)
//   tint         : vec4 source_color — blood ember (#b4452f)
//   edge_width   : float — vignette thickness 0.05..0.5 (0.30)
// Usage: CanvasLayer -> TextureRect(full, transparent)/ColorRect with material;
//        $Rect.material.set_shader_parameter("strength", clamp(hp_deficit, 0, 1))
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_bpm : hint_range(20.0, 180.0) = 60.0;
uniform vec4 tint : source_color = vec4(0.706, 0.271, 0.184, 1.0);
uniform float edge_width : hint_range(0.05, 0.5) = 0.30;

void fragment() {
    vec2 c = SCREEN_UV - 0.5;
    float d = length(c) * 1.4142;
    float mask = smoothstep(1.0 - edge_width, 1.0, d);
    float beat = 0.55 + 0.45 * sin(TIME * pulse_bpm * 6.283185 / 60.0);
    float a = mask * strength * beat;
    COLOR = vec4(tint.rgb, a);
}
