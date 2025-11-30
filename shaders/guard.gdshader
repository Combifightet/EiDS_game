shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform float vision_angle_deg = 60.0;
uniform vec4 color : source_color = vec4(1.0, 0.0, 0.0, 0.3);

void fragment() {
    // 1. Center the UVs (0.0 to 1.0) so (0,0) is in the middle
    vec2 centered_uv = UV - vec2(0.5, 0.5);
    
    // 2. Calculate Angle
    // Rotate 90 degrees (PI/2) to align with Godot's Forward (-Z)
    float angle_rad = atan(centered_uv.y, centered_uv.x) + (PI / 2.0);
    float angle_deg = degrees(angle_rad);
    
    // Normalize angle to -180 to 180
    if (angle_deg > 180.0) angle_deg -= 360.0;
    if (angle_deg < -180.0) angle_deg += 360.0;
    
    // 3. The Pie Slice Logic
    if (abs(angle_deg) > vision_angle_deg / 2.0) {
        discard;
    }
    
    // 4. Soft Edge (optional)
    float dist = length(centered_uv) * 2.0;
    if (dist > 1.0) discard; // Cut circle exact
    
    ALBEDO = color.rgb;
    ALPHA = color.a;
}