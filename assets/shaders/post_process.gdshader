shader_type canvas_item;

// Post-process: color correction + vignette + film grain (GDD §11.2/§11.4/§11.6)
// Канон: vignette → #0c1016 (не чистый #000), grain 8–12% opacity.
uniform float bloom_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.55;
uniform vec4 color_tint : source_color = vec4(1.0, 0.95, 0.9, 1.0);
uniform float damage_flash : hint_range(0.0, 1.0) = 0.0;
uniform float grain_amount : hint_range(0.0, 0.2) = 0.10;   // 8–12% по GDD §11.4
uniform float grain_speed : hint_range(0.0, 3.0) = 0.8;
uniform float grain_scale : hint_range(40.0, 200.0) = 110.0;
const vec4 VIGNETTE_COLOR = vec4(0.047, 0.062, 0.086, 1.0); // #0c1016 — bg-deep

float _grain_hash(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    // Color correction (warm tone)
    col.rgb *= color_tint.rgb;

    // Vignette: плавный тёмный bg-deep к краям (не multiply — replace).
    vec2 uv_centered = UV - vec2(0.5);
    float dist = length(uv_centered * vec2(1.7, 1.0));
    float mask = smoothstep(0.3, 1.0, dist);
    col.rgb = mix(col.rgb, VIGNETTE_COLOR.rgb, vignette_intensity * mask);

    // Damage flash (red overlay)
    col.rgb = mix(col.rgb, vec3(1.0, 0.0, 0.0), damage_flash * 0.5);

    // Film grain
    vec2 offset = vec2(TIME * grain_speed * 0.3, TIME * grain_speed * 0.17);
    float g = _grain_hash((UV + offset) * grain_scale);
    col.rgb += (g - 0.5) * grain_amount;

    COLOR = col;
}
