shader_type spatial;

uniform vec4 color: source_color = vec4(1, 0.55, 0.57, 0.9);

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}

void light() {

	//ALPHA = 0.1;
	//DIFFUSE_LIGHT = vec3(length(LIGHT));
	//DIFFUSE_LIGHT = vec3(1.0);
	//ALPHA = length(LIGHT);

	// out vec3 DIFFUSE_LIGHT
	// Diffuse light result.

	// out vec3 SPECULAR_LIGHT
	// Specular light result.

	// out float ALPHA
	// Alpha (range of [0.0, 1.0]). If written to, the material will go to the transparent pipeline.
}
