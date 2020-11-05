shader_type canvas_item;

uniform vec4 base : hint_color;
uniform sampler2D vignette;
uniform float amount: hint_range(0, 6);

void fragment() {
	COLOR.rgba = textureLod(SCREEN_TEXTURE, SCREEN_UV, (1.0 - texture(vignette, UV).r) * amount).rgba * base.rgba;
}