shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Controles de tinte
uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform vec3 tint_color = vec3(0.6, 0.2, 1.0);

// Controles de niebla
uniform float fog_amount : hint_range(0.0, 1.0) = 0.6;
uniform float fog_scale = 3.0;
uniform float fog_speed = 0.5;

// Controles de partículas
uniform float particle_density : hint_range(10.0, 200.0) = 200.0;
uniform float particle_size : hint_range(0.5, 3.0) = 2.5; // tamaño en píxeles
uniform vec2 particle_speed = vec2(0.6, 0.9); // velocidad X e Y
uniform float particle_brightness : hint_range(0.0, 3.0) = 2.0;

uniform float time;

// Función hash para aleatoriedad
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Ruido simple
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

// Niebla con múltiples capas
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

    // 1. APLICAR TINTE VIOLETA
    vec3 tinted = mix(screen_color.rgb, tint_color, intensity);

    // 2. NIEBLA VIOLETA
    vec2 fog_uv1 = SCREEN_UV * fog_scale + vec2(time * fog_speed * 0.1, time * fog_speed * 0.05);
    vec2 fog_uv2 = SCREEN_UV * fog_scale * 1.5 - vec2(time * fog_speed * 0.08, time * fog_speed * 0.12);

    float fog1 = fbm(fog_uv1);
    float fog2 = fbm(fog_uv2);
    float fog = (fog1 + fog2) * 0.5;

    vec3 fog_color = tint_color * 1.2;
    vec3 with_fog = mix(tinted, fog_color, fog * fog_amount);

    // 3. PARTÍCULAS PÍXELES PEQUEÑOS
    // Obtener coordenadas en píxeles de pantalla
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 pixel_pos = SCREEN_UV * screen_size;

    float particles = 0.0;

    // Generar partículas distribuidas por toda la pantalla
    for(float i = 0.0; i < particle_density; i++) {
        // Posición base aleatoria para cada partícula
        vec2 particle_seed = vec2(i * 0.1, i * 0.7);
        float offset_x = hash(particle_seed) * screen_size.x;
        float offset_y = hash(particle_seed + vec2(10.0, 20.0)) * screen_size.y;

        // Movimiento de la partícula
        vec2 particle_pos = vec2(
            mod(offset_x + time * particle_speed.x * 50.0, screen_size.x),
            mod(offset_y + time * particle_speed.y * 30.0, screen_size.y)
        );

        // Distancia del pixel actual a la partícula
        vec2 diff = pixel_pos - particle_pos;
        float dist = length(diff);

        // Crear el punto/píxel (muy pequeño)
        if(dist < particle_size) {
            // Parpadeo suave
            float flicker = sin(time * 3.0 + i * 0.5) * 0.3 + 0.7;
            particles += flicker;
        }
    }

    // Agregar partículas con color violeta brillante
    vec3 particle_color = tint_color * particle_brightness;
    vec3 final_color = with_fog + particle_color * particles;

	// qué tan iluminado está el pixel
	float luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));

	// más luz = menos filtro
	float light_factor = smoothstep(0.2, 0.8, luminance);

	// Reducir efecto del filtro en zonas iluminadas
	final_color = mix(final_color, screen_color.rgb, light_factor);

    COLOR = vec4(final_color, 1);
}
