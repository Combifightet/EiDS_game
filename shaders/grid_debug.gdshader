shader_type canvas_item;

uniform sampler2D data_texture : filter_nearest;
uniform vec2 data_size;
uniform vec2 container_size; // <-- ADDED: The size of the ColorRect
uniform float grid_line_width : hint_range(0.0, 0.5) = 0.1;
uniform vec4 grid_color : source_color = vec4(0.12, 0.13, 0.15, 1.0);

void fragment() {
    // --- REPLACED LOGIC ---
    
    // 1. Calculate aspect ratios
    float data_aspect = data_size.x / data_size.y;
    float container_aspect = container_size.x / container_size.y;

    // 2. Calculate the scale needed to "zoom" the UVs
    vec2 scale = vec2(1.0);
    if (data_aspect > container_aspect) {
        // Data is wider than container (e.g., 16:9 data in 4:3 container)
        // We need to letterbox. Scale UV.y to "zoom out" vertically.
        scale.y = data_aspect / container_aspect;
    } else {
        // Data is taller than container (e.g., 4:3 data in 16:9 container)
        // We need to pillarbox. Scale UV.x to "zoom out" horizontally.
        scale.x = container_aspect / data_aspect;
    }

    // 3. Apply scale to centered UVs
    // This scales the UVs *beyond* the 0.0-1.0 range in the pillar/letterbox direction.
    vec2 centered_uv = (UV - 0.5) * scale + 0.5;
    
    // --- END REPLACED LOGIC ---

    // Clamp to valid texture range
    if (centered_uv.x < 0.0 || centered_uv.x > 1.0 || 
        centered_uv.y < 0.0 || centered_uv.y > 1.0) {
        
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // Outside bounds (black bars)
    
    } else {
        // We are inside the texture bounds
        COLOR.rgb = texture(data_texture, centered_uv).rgb;
        
        // Draw grid lines
        vec2 pixel_coord = centered_uv * data_size;
        vec2 grid_pos = fract(pixel_coord);
        
        // Check if we're close to a grid line (edge of pixel)
        if (grid_pos.x < grid_line_width || grid_pos.x > 1.0 - grid_line_width ||
            grid_pos.y < grid_line_width || grid_pos.y > 1.0 - grid_line_width) {
            COLOR = grid_color;
        }
    }
}