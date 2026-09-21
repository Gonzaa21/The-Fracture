shader_type canvas_item;

uniform int hframes = 9; 

uniform float vignette_intensity : hint_range(0.0, 4.0) = 1.5;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.7;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	vec2 frame_uv = UV;
	frame_uv.x = fract(UV.x * float(hframes));
	
	float dist = distance(frame_uv, vec2(0.5));
	
	float vignette = pow(dist * vignette_intensity, 2.0);
	vignette = clamp(vignette, 0.0, 1.0) * vignette_opacity;
	
	vec3 final_color = mix(tex_color.rgb, shadow_color.rgb, vignette);
	COLOR = vec4(final_color, tex_color.a * COLOR.a);
}
