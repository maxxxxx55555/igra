shader_type spatial;
render_mode blend_mix, diffuse_burley, specular_schlick_ggx;

uniform float window_density: hint_range(0.0, 1.0) = 0.3;
uniform float window_emission_strength: hint_range(0.0, 5.0) = 2.0;

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
    vec3 normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    vec3 abs_n = abs(normal);

    float scale = 1.5;
    vec2 uv_xy = world_pos.xy * scale;
    vec2 uv_xz = world_pos.xz * scale;
    vec2 uv_zy = world_pos.zy * scale;

    float n_xy = fbm(uv_xy);
    float n_xz = fbm(uv_xz);
    float n_zy = fbm(uv_zy);

    float total = abs_n.x + abs_n.y + abs_n.z;
    float n = (n_xy * abs_n.z + n_xz * abs_n.y + n_zy * abs_n.x) / max(total, 0.001);

    vec3 dark = vec3(0.11, 0.14, 0.18);
    vec3 lit = vec3(0.14, 0.17, 0.21);
    vec3 base = mix(dark, lit, n);

    float streak = (fbm(vec2(world_pos.y * 0.5, world_pos.x * 0.1)) - 0.5) * 0.06;
    base += streak;

    vec2 win_uv = world_pos.xz * 0.3;
    vec2 win_cell = floor(win_uv);
    vec2 win_local = fract(win_uv) - 0.5;
    float win_dist = max(abs(win_local.x), abs(win_local.y));
    bool is_window = win_dist < 0.42;

    float wh = hash(win_cell + vec2(7.77, 3.33));
    bool is_lit = wh < window_density && is_window;

    vec2 j_uv = world_pos.xz * 0.5;
    vec2 jf = fract(j_uv);
    vec2 jl = step(0.96, jf);
    float joint = max(jl.x, jl.y) * 0.25;

    ALBEDO = base;
    ALBEDO -= joint;

    if (is_lit) {
        EMISSION = vec3(1.0, 0.81, 0.48) * window_emission_strength;
    } else if (is_window) {
        ALBEDO = vec3(0.04, 0.05, 0.07);
    }

    ROUGHNESS = 0.9;
    METALLIC = 0.0;
}
