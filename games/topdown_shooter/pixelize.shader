shader_type canvas_item;

uniform float size_x = 0.008;
uniform float size_y = 0.008;
uniform vec4 base : hint_color;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv -= mod(uv, vec2(size_x, size_y));

	COLOR.rgba = textureLod(SCREEN_TEXTURE, uv, 0.0).rgba * base.rgba;
}
