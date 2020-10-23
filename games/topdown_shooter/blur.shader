shader_type canvas_item;

uniform vec4 base : hint_color;
uniform sampler2D vignette;
uniform float amount: hint_range(0, 4);

void fragment() {
	vec3 vignette_color = texture(vignette, UV).rgb;
	COLOR.rgba = textureLod(SCREEN_TEXTURE, SCREEN_UV, (1.0 - vignette_color.r) * amount).rgba * base.rgba;
	//COLOR.rgb = vignette_color;	// to test position
}