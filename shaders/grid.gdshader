shader_type spatial;

uniform vec3 color_a: source_color = vec3(0.21, 0.24, 0.29); // (0.11, 0.13, 0.16, 1)
uniform vec3 color_b: source_color = vec3(0.11, 0.13, 0.16); // (0.21, 0.24, 0.29, 1)

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ivec3 stripes = ivec3(
		floor(world_position)
	);
	
	if ((stripes.x+stripes.y+stripes.z)%2 > 0) {
		ALBEDO = color_a;
	} else {
		ALBEDO = color_b;
	}
}