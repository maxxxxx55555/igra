shader_type spatial;
render_mode blend_mix, diffuse_burley, specular_schlick_ggx;

uniform float noise_scale: hint_range(0.5, 10.0) = 3.0;
uniform float puddle_threshold: hint_range(0.0, 1.0) = 0.55;
uniform float crack_intensity: hint_range(0.0, 0.5) = 0.12;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float fbm(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 uv = world_pos.xz / noise_scale;

    float n = fbm(uv);
    float n2 = fbm(world_pos.xz / 2.0);

    vec3 dark = vec3(0.18, 0.20, 0.22);
    vec3 light = vec3(0.23, 0.25, 0.28);
    vec3 base = mix(dark, light, n);

    float puddle = step(puddle_threshold, n2);

    vec2 crack_uv = world_pos.xz * 3.0;
    vec2 cf = fract(crack_uv);
    vec2 cc = abs(cf - 0.5);
    float crack = step(0.47, max(cc.x, cc.y));
    crack *= crack_intensity * (0.5 + n * 0.5);

    ALBEDO = base - crack;
    METALLIC = puddle * 0.7;
    ROUGHNESS = mix(0.85, 0.15, puddle);
}
