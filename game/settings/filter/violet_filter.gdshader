shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Controles de tinte
uniform float intensity : hint_range(0.0, 1.0) = 0.6;
uniform vec3 tint_color = vec3(0.6, 0.2, 1.0);

// Controles de niebla
uniform float fog_amount : hint_range(0.0, 1.0) = 0.8;
uniform float fog_scale = 3.0;
uniform float fog_speed = 0.5;

// Controles de partículas
uniform float particle_density : hint_range(10.0, 200.0) = 100.0;
uniform float particle_size : hint_range(0.5, 3.0) = 3.0;
uniform vec2 particle_speed = vec2(0.6, 0.9);
uniform float particle_brightness : hint_range(0.0, 3.0) = 1.5;

// Controles de vignette
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_size : hint_range(0.0, 2.0) = 1.0;

// Círculo mínimo alrededor del jugador (el radio lo controla filter.gd)
uniform vec2 player_position = vec2(0.5, 0.5);
uniform float visibility_radius : hint_range(0.0, 400.0) = 24.0;
uniform float visibility_softness : hint_range(1.0, 200.0) = 14.0;

// Linterna (cono)
uniform float flashlight_enabled : hint_range(0.0, 1.0) = 0.0;
uniform vec2 flashlight_dir = vec2(1.0, 0.0);
uniform float flashlight_range : hint_range(20.0, 400.0) = 200.0;
uniform float flashlight_range_softness : hint_range(1.0, 200.0) = 40.0;
uniform float flashlight_half_angle : hint_range(0.1, 1.5) = 0.5;        // radianes
uniform float flashlight_edge_softness : hint_range(0.05, 1.0) = 0.45;   // 0 = borde duro
uniform float flashlight_origin_offset = 6.0;

// Oscuridad fuera de la luz
uniform float darkness : hint_range(0.0, 1.0) = 0.8;

uniform float time;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for(int i = 0; i < 3; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 pixel_pos = SCREEN_UV * screen_size;
    vec2 player_pixel_pos = player_position * screen_size;

    // 1. LUZ: círculo mínimo + cono de la linterna
    float dist_to_player = distance(pixel_pos, player_pixel_pos);
    float ambient = 1.0 - smoothstep(visibility_radius, visibility_radius + visibility_softness, dist_to_player);

    float cone = 0.0;
    if (flashlight_enabled > 0.001) {
        vec2 dir = normalize(flashlight_dir);
        vec2 v = pixel_pos - (player_pixel_pos + dir * flashlight_origin_offset);
        float d = length(v);
        if (d > 0.001) {
            float c = dot(v / d, dir);
            float cos_outer = cos(flashlight_half_angle);
            float cos_inner = cos(flashlight_half_angle * (1.0 - flashlight_edge_softness));
            float angular = smoothstep(cos_outer, cos_inner, c);
            float radial = 1.0 - smoothstep(flashlight_range - flashlight_range_softness, flashlight_range, d);
            float falloff = mix(1.0, 0.6, clamp(d / flashlight_range, 0.0, 1.0));
            cone = angular * radial * falloff * flashlight_enabled;
        }
    }

    // 1.0 = oscuro, 0.0 = visible
    float visibility_mask = 1.0 - max(ambient, cone);

    // 2. TINTE VIOLETA
    vec3 tinted = mix(screen_color.rgb, tint_color, intensity);

    // 3. NIEBLA VIOLETA (más intensa lejos de la luz)
    vec2 fog_uv1 = SCREEN_UV * fog_scale + vec2(time * fog_speed * 0.1, time * fog_speed * 0.05);
    vec2 fog_uv2 = SCREEN_UV * fog_scale * 1.5 - vec2(time * fog_speed * 0.08, time * fog_speed * 0.12);

    float fog1 = fbm(fog_uv1);
    float fog2 = fbm(fog_uv2);
    float fog = (fog1 + fog2) * 0.5;

    float dynamic_fog = fog * fog_amount * visibility_mask;

    vec3 fog_color = tint_color * 1.2;
    vec3 with_fog = mix(tinted, fog_color, dynamic_fog);

    // 4. PARTÍCULAS (reducidas dentro de la luz)
    float particles = 0.0;

    for(float i = 0.0; i < particle_density; i++) {
        vec2 particle_seed = vec2(i * 0.1, i * 0.7);
        float offset_x = hash(particle_seed) * screen_size.x;
        float offset_y = hash(particle_seed + vec2(10.0, 20.0)) * screen_size.y;

        vec2 particle_pos = vec2(
            mod(offset_x + time * particle_speed.x * 50.0, screen_size.x),
            mod(offset_y + time * particle_speed.y * 30.0, screen_size.y)
        );

        float dist = distance(pixel_pos, particle_pos);

        if(dist < particle_size) {
            float flicker = sin(time * 3.0 + i * 0.5) * 0.3 + 0.7;
            particles += flicker * visibility_mask;
        }
    }

    vec3 particle_color = tint_color * particle_brightness;
    vec3 final_color = with_fog + particle_color * particles * 0.01;

    // 5. PRESERVAR ZONAS MUY ILUMINADAS
    float luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
    float light_factor = smoothstep(0.15, 0.6, luminance);
    final_color = mix(final_color, screen_color.rgb, light_factor * 1.0);

    // 6. VIGNETTE GENERAL
    vec2 uv_centered = SCREEN_UV - 0.5;
    float vignette = length(uv_centered) / vignette_size;
    vignette = smoothstep(0.0, 1.0, vignette);
    vignette = pow(vignette, 2.0);

    final_color = mix(final_color, vec3(0.0), vignette * vignette_intensity);

    // 7. OSCURECIMIENTO fuera de la luz
    final_color = mix(final_color, vec3(0.0), visibility_mask * darkness);

    COLOR = vec4(final_color, 1.0);
}