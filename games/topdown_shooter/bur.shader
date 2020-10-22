shader_type canvas_item;

uniform float amount: hint_range(0.0, 5.0);
uniform float darkness: hint_range(0.0, 1);

void fragment() {
	//COLOR.rgb = textureLod(SCREEN_TEXTURE, SCREEN_UV, amount).rgb;
	
	//COLOR.rgba = texture(TEXTURE, UV); // mask
	COLOR.rgba *= texture(TEXTURE, UV);
	COLOR.rgba *= textureLod(SCREEN_TEXTURE, SCREEN_UV, amount);
	
	//COLOR.rgb -= vec3(darkness, darkness, darkness);
	//COLOR.rgb *= darkness;
}
