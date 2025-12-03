shader_type spatial;

uniform vec4 color: source_color = vec4(1, 0.55, 0.57, 0.9);
uniform float angle: hint_range(0.0, PI, 0.01) = 0.698132; // 40°
uniform uint id = 0;

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
	ALPHA = 0.2; // only for debugging
}

void light() {
	uint light_id = uint(max(0, round(LIGHT_COLOR.x/PI)));
	if (id == light_id) {
		ALPHA = step(0.001, ATTENUATION) * cone_mask * color.a;
	}

	DIFFUSE_LIGHT = vec3(1.0);
}
