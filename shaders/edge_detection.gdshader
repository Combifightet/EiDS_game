shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;


uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE: hint_normal_roughness_texture, filter_linear_mipmap;

uniform float lineHighlight: hint_range(0.0, 1.0, 0.01) =  0.2;
uniform float lineShadow:    hint_range(0.0, 1.0, 0.01) = 0.55;



float getLinearDepth(vec2 screen_uv, sampler2D depthTexture, mat4 invProjectionMat, float mask){
	// Raw depth to linear depth code from:
	// https://docs.godotengine.org/en/latest/tutorials/shaders/advanced_postprocessing.html
	float depth = texture(depthTexture, screen_uv).x * mask;
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
    vec4 view = invProjectionMat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

vec3 getNormal(vec2 uv, sampler2D normalTexture, float mask){
	vec3 normal = texture(normalTexture, uv).rgb;
	normal = normal * 2.0 - 1.0 * mask;
	return normal;
}

float normalEdgeIndicator(vec3 normalEdgeBias, vec3 normal, vec3 neighborNormal, float depthDifference){
	//From Kody King: https://threejs.org/examples/webgl_postprocessing_pixel.html
	float normalDifference = dot(normal - neighborNormal, normalEdgeBias);
	float normalIndicator = clamp(smoothstep(-.01, .01, normalDifference), 0.0, 1.0);
	float depthIndicator = clamp(sign(depthDifference * .25 + .0025), 0.0, 1.0);
	return (1.0 - dot(normal, neighborNormal)) * depthIndicator * normalIndicator;
}



void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}


void fragment() {
	vec2 texelSize = 1.0/VIEWPORT_SIZE.xy;
	vec2 offsetUV[4];

	offsetUV[0] = SCREEN_UV + vec2( 0.0, -1.0) * texelSize;    // top
	offsetUV[1] = SCREEN_UV + vec2(-1.0,  0.0) * texelSize;    // left
	offsetUV[2] = SCREEN_UV + vec2( 0.0,  1.0) * texelSize;    // bottom
	offsetUV[3] = SCREEN_UV + vec2( 1.0,  0.0) * texelSize;    // right


	// Using alpha channel (screen roughness) to mask objects to not receive outlines
	float outlineMask = texture(NORMAL_TEXTURE, SCREEN_UV).a;
	outlineMask = ceil(outlineMask); // Objects with Roughness = 0 will not have and outline


	float depth  = getLinearDepth(SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX, outlineMask);
	float depthDiff = 0.0;
	float depthDiffInverse = 0.5;
	for (int i=0; i<offsetUV.length(); i++) {
		float offsetDepth = getLinearDepth(
			offsetUV[i],
			DEPTH_TEXTURE,
			INV_PROJECTION_MATRIX,
			outlineMask
		);
		depthDiff += clamp(offsetDepth - depth, 0.0, 1.0);
		depthDiffInverse += depth - offsetDepth;
	}
	depthDiff = smoothstep(0.25, 0.3, depthDiff);
	depthDiffInverse = clamp(depthDiffInverse, 0.0, 1.0);
	depthDiffInverse = clamp(smoothstep(0.9, 0.9, depthDiffInverse)*10.0, 0.0, 1.0);


	vec3 normal = getNormal(SCREEN_UV, NORMAL_TEXTURE, outlineMask);
	float normalDiff = 0.0;
	vec3 normalEdgeBias = vec3(1.0);
	for (int i=0; i<offsetUV.length(); i++) {
		normalDiff += normalEdgeIndicator(
			normalEdgeBias,
			normal,
			getNormal(offsetUV[i], NORMAL_TEXTURE, outlineMask),
			depthDiff
		);
	}
	normalDiff = smoothstep(0.2, 0.2, normalDiff);
	normalDiff = clamp(normalDiff-depthDiffInverse, 0.0, 1.0);


	ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	float innerLines = clamp(normalDiff-depthDiff, 0.0, 1.0);

	ALBEDO += innerLines*lineHighlight;
	ALBEDO -= ALBEDO*depthDiff*lineShadow;

}

void light() {
	DIFFUSE_LIGHT = vec3(1.0);
}
