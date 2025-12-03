shader_type spatial;

uniform vec4 color: source_color = vec4(1, 0.55, 0.57, 0.9);

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = 0.0;
}

void light() {

	//ALPHA = 0.1;
	//DIFFUSE_LIGHT = vec3(length(LIGHT));
	//DIFFUSE_LIGHT = vec3(1.0);
	//ALPHA = length(LIGHT);
	float l = length(LIGHT)*ATTENUATION;

	if (l > 0.001) {
		ALPHA = color.a;
		DIFFUSE_LIGHT = vec3(1.0);
	}
}
