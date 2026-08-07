shader_type canvas_item;

uniform float bloom_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform vec4 color_tint : source_color = vec4(1.0, 0.95, 0.9, 1.0);
uniform float damage_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    
    // Color correction (warm tone)
    col.rgb *= color_tint.rgb;
    
    // Vignette
    vec2 uv = UV * 2.0 - 1.0;
    float vignette = 1.0 - dot(uv, uv) * vignette_intensity;
    col.rgb *= vignette;
    
    // Damage flash (red overlay)
    col.rgb = mix(col.rgb, vec3(1.0, 0.0, 0.0), damage_flash * 0.5);
    
    COLOR = col;
}