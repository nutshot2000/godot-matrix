shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// ===== FULL TERRAIN SHADER =====
// Combines: Height blending, Slope blending, Triplanar projection

// Texture layers
uniform sampler2D texture_grass : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_dirt : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_rock : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_snow : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_cliff : source_color, filter_linear_mipmap, repeat_enable;

// Normal maps
uniform sampler2D normal_grass : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_rock : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_cliff : hint_normal, filter_linear_mipmap, repeat_enable;

// Height thresholds
uniform float height_grass : hint_range(0.0, 1.0) = 0.0;
uniform float height_dirt : hint_range(0.0, 1.0) = 0.3;
uniform float height_rock : hint_range(0.0, 1.0) = 0.6;
uniform float height_snow : hint_range(0.0, 1.0) = 1.0;
uniform float max_terrain_height = 20.0;

// Blending
uniform float texture_scale : hint_range(0.01, 1.0) = 0.1;
uniform float blend_sharpness : hint_range(0.1, 10.0) = 2.0;
uniform float slope_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float triplanar_sharpness : hint_range(1.0, 8.0) = 4.0;

// PBR
uniform float roughness_base : hint_range(0.0, 1.0) = 0.75;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.3;

varying vec3 world_pos;
varying vec3 world_normal;
varying float vertex_height;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    vertex_height = VERTEX.y / max_terrain_height;
}

vec3 triplanar_sample(sampler2D tex, vec3 pos, vec3 blend) {
    vec3 x = texture(tex, pos.zy * texture_scale).rgb;
    vec3 y = texture(tex, pos.xz * texture_scale).rgb;
    vec3 z = texture(tex, pos.xy * texture_scale).rgb;
    return x * blend.x + y * blend.y + z * blend.z;
}

void fragment() {
    vec2 uv_scaled = UV * (1.0 / texture_scale);
    
    // ===== TRIPLANAR SETUP =====
    vec3 tri_blend = abs(world_normal);
    tri_blend = pow(tri_blend, vec3(triplanar_sharpness));
    tri_blend /= (tri_blend.x + tri_blend.y + tri_blend.z);
    
    // ===== SLOPE CALCULATION =====
    float slope = 1.0 - abs(world_normal.y);
    float cliff_blend = smoothstep(slope_threshold - 0.1, slope_threshold + 0.1, slope);
    cliff_blend = pow(cliff_blend, blend_sharpness);
    
    // ===== HEIGHT BLENDING =====
    float h = clamp(vertex_height, 0.0, 1.0);
    
    float w_grass = 1.0 - smoothstep(height_grass, height_dirt, h);
    float w_dirt = smoothstep(height_grass, height_dirt, h) * (1.0 - smoothstep(height_dirt, height_rock, h));
    float w_rock = smoothstep(height_dirt, height_rock, h) * (1.0 - smoothstep(height_rock, height_snow, h));
    float w_snow = smoothstep(height_rock, height_snow, h);
    
    // Sharpen
    w_grass = pow(w_grass, blend_sharpness);
    w_dirt = pow(w_dirt, blend_sharpness);
    w_rock = pow(w_rock, blend_sharpness);
    w_snow = pow(w_snow, blend_sharpness);
    
    // Normalize
    float total = w_grass + w_dirt + w_rock + w_snow + 0.001;
    w_grass /= total; w_dirt /= total; w_rock /= total; w_snow /= total;
    
    // ===== SAMPLE TEXTURES =====
    // Flat areas use standard UV, cliffs use triplanar
    vec3 grass = mix(texture(texture_grass, uv_scaled).rgb, triplanar_sample(texture_grass, world_pos, tri_blend), cliff_blend * 0.5);
    vec3 dirt = mix(texture(texture_dirt, uv_scaled).rgb, triplanar_sample(texture_dirt, world_pos, tri_blend), cliff_blend * 0.5);
    vec3 rock = mix(texture(texture_rock, uv_scaled).rgb, triplanar_sample(texture_rock, world_pos, tri_blend), cliff_blend * 0.5);
    vec3 snow = texture(texture_snow, uv_scaled).rgb;
    vec3 cliff = triplanar_sample(texture_cliff, world_pos, tri_blend);
    
    // Height-based base color
    vec3 height_color = grass * w_grass + dirt * w_dirt + rock * w_rock + snow * w_snow;
    
    // Blend with cliff texture based on slope
    ALBEDO = mix(height_color, cliff, cliff_blend);
    
    // ===== NORMALS =====
    vec3 n_base = texture(normal_rock, uv_scaled).rgb * 2.0 - 1.0;
    vec3 n_cliff = triplanar_sample(normal_cliff, world_pos, tri_blend) * 2.0 - 1.0;
    NORMAL_MAP = normalize(mix(n_base, n_cliff, cliff_blend)) * 0.5 + 0.5;
    
    // ===== PBR OUTPUT =====
    ROUGHNESS = roughness_base + cliff_blend * 0.15;
    METALLIC = 0.0;
    AO = 1.0 - (cliff_blend * ao_strength);
}
