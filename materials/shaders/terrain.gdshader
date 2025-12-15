shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx;

varying vec2 world_pos;

uniform vec2 world_offset = vec2(0);
uniform bool debug = false;

group_uniforms GridData;
uniform isampler2D room_ids : repeat_disable, filter_nearest;
uniform float grid_size = 1.0;
uniform ivec2 grid_offset = ivec2(0);

group_uniforms Colors;
uniform vec3 inside : source_color = vec3(0.3, 0.6, 0.4);
uniform vec3 border : source_color = vec3(0.5, 0.4, 0.3);
uniform vec3 outside : source_color = vec3(0.6, 0.3, 0.5);



vec2 snap(vec2 value, float step_size) {
	return floor(value/step_size)*step_size;
}



void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	world_pos += world_offset;
}


void fragment() {
	ivec2 grid_position = ivec2(floor(world_pos/grid_size)) + grid_offset;

	ivec3 texel_color = texelFetch(room_ids, grid_position, 0).rgb;

	float cell_has_room = float(texel_color.g);
	cell_has_room = clamp(cell_has_room, 0.0, 1.0);

	// includes self as neighbour
	float cell_has_neighbour = 0.0;
	for (int y=-1; y<=1; y++) {
		for (int x=-1; x<=1; x++) {
			ivec3 neighbour_color = texelFetch(room_ids, grid_position+ivec2(x, y), 0).rgb;
			cell_has_neighbour += float(neighbour_color.g);
		}
	}
	cell_has_neighbour = clamp(cell_has_neighbour, 0.0, 1.0);



	//ALBEDO = inside*cell_has_room + outside*(1.0-cell_has_room);
	ALBEDO = inside*cell_has_room + (border*cell_has_neighbour+outside*(1.0-cell_has_neighbour))*(1.0-cell_has_room);

	if (debug) {
		float checker = float((grid_position.x+grid_position.y)%2);
		ALBEDO *= checker*0.2+0.8;
	}
}
