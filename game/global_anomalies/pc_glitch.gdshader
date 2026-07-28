shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset = 0.0;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	float line_noise = random(vec2(floor(uv.y * 40.0), time_offset));
	float jitter = (line_noise - 0.5) * intensity * 0.03;
	uv.x += jitter;
	
	float tear_trigger = step(0.985, random(vec2(floor(time_offset * 8.0), 0.0)));
	float tear_offset = (random(vec2(floor(time_offset * 8.0), 1.0)) - 0.5) * 0.15 * tear_trigger * (intensity * 4.5);
	uv.y += tear_offset;
	
	float aberration = intensity * 0.004;
	vec4 col_r = texture(SCREEN_TEXTURE, uv + vec2(aberration, 0.0));
	vec4 col_g = texture(SCREEN_TEXTURE, uv);
	vec4 col_b = texture(SCREEN_TEXTURE, uv - vec2(aberration, 0.0));
	vec4 final_color = vec4(col_r.r, col_g.g, col_b.b, col_g.a);
	
	float flicker = 1.0 - (random(vec2(time_offset * 30.0, 5.0)) * (intensity * 4.5) * 0.15);
	final_color.rgb *= flicker;
	
	float static_noise = random(uv * 500.0 + time_offset) * (intensity * 4.5) * 0.08;
	final_color.rgb += static_noise;
	
	COLOR = final_color;
}