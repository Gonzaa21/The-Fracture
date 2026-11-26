shader_type canvas_item;

uniform float skew_x : hint_range(-2.0, 2.0) = 0.7;
uniform float skew_y : hint_range(-2.0, 2.0) = 0.0;

void vertex() {
    VERTEX.x += VERTEX.y * skew_x;
    VERTEX.y += VERTEX.x * skew_y;
}
