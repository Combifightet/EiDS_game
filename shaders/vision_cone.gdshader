shader_type spatial;

uniform vec4 color: source_color = vec4(1, 0.55, 0.57, 0.9);
uniform float angle: hint_range(0.0, PI, 0.01) = 0.698132; // 40°
uniform vec3 id = vec3(0.0);

varying float cone_mask;

void fragment() {
	// convert UV to centered polar coordinates
	vec2 polar = vec2(
		length(UV*2.0-1.0), // distance
		atan(UV.x*2.0-1.0, UV.y*2.0-1.0) // angle
	);

	float circle_mask = step(polar.x, 1.0);
	float angle_mask = step(abs(polar.y), angle/2.0);
	cone_mask = circle_mask*angle_mask;

	ALBEDO = color.rgb;
	ALPHA = 0.0;
}


bool is_equal_approx(float a, float b) {
	if (a==b) {
		return true;
	}

	return (abs(a-b) < 0.000001);
}

void light() {
	if (is_equal_approx(id.x, LIGHT_COLOR.x/PI)) {
		ALPHA = step(0.001, ATTENUATION) * cone_mask * color.a;
	}

	DIFFUSE_LIGHT = vec3(1.0);
}