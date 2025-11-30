shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.08, 0.09, 0.12, 1.0);

// Cinemascope aspect ratio (2.35:1)
//uniform float aspect_ratio : hint_range(0.0, 5.0, 0.01) = 2.35;
// TODO: make this uniform actualy work

uniform float bar_ratio : hint_range(0.0, 0.5, 0.001) = 0.125;

uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.9;

void fragment() {
	vec2 uv = UV-vec2(0.5, 0.5);

	float mask = sign(abs(uv.y)-(0.5-bar_ratio));

	float vignette = length(vec2(uv.x, uv.y/(2.0*(0.5-bar_ratio))));
	vignette *= 1.3;
	vignette = pow(vignette, 3);

	COLOR = vec4(color.rgb, color.a*max(mask, vignette*vignette_strength));
}