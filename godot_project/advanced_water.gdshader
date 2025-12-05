shader_type spatial;
render_mode specular_schlick_ggx, depth_draw_always, cull_back;

// --- Colors ---
uniform vec3 albedo : source_color = vec3(0.0, 0.19, 0.28); // Darker base
uniform vec3 albedo_deep : source_color = vec3(0.0, 0.05, 0.15); // Very dark deeps
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.04;

// --- Gerstner Wave Parameters ---
uniform vec4 wave_a = vec4(1.0, 0.5, 0.15, 60.0); 
uniform vec4 wave_b = vec4(0.0, 1.0, 0.15, 30.0); 
uniform vec4 wave_c = vec4(0.5, 0.5, 0.1, 10.0);

// --- Noise for Chaos ---
uniform sampler2D noise_tex; // For vertex offset
uniform float noise_scale = 50.0;
uniform float noise_height = 1.0;

// --- Foam & Depth ---
uniform float beer_law_factor = 0.5; 
uniform float edge_scale = 1.0;
uniform vec4 foam_color : source_color = vec4(1.0);

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Gerstner Wave Function
vec3 gerstner_wave(vec4 wave, vec3 p, inout vec3 tangent, inout vec3 binormal) {
	float steepness = wave.z;
	float wavelength = wave.w;
	float k = 2.0 * 3.14159 / wavelength;
	float c = sqrt(9.8 / k);
	vec2 d = normalize(wave.xy);
	
	float f = k * (dot(d, p.xz) - c * TIME);
	float a = steepness / k; // Amplitude
	
	// Derivatives for normals
	float wa = k * a; // slope
	float s = sin(f);
	float co = cos(f);
	
	tangent += vec3(
		-d.x * d.x * (wa * s),
		d.x * (wa * co),
		-d.x * d.y * (wa * s)
	);
	binormal += vec3(
		-d.x * d.y * (wa * s),
		d.y * (wa * co),
		-d.y * d.y * (wa * s)
	);
	
	return vec3(
		d.x * (a * co),
		a * s,
		d.y * (a * co)
	);
}

void vertex() {
	vec3 grid_point = VERTEX;
	
	// Add Large Scale Noise to break uniformity
	float noise_val = texture(noise_tex, (grid_point.xz + TIME * 2.0) / noise_scale).r;
	grid_point.y += (noise_val - 0.5) * noise_height;
	
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 p = grid_point;
	
	p += gerstner_wave(wave_a, grid_point, tangent, binormal);
	p += gerstner_wave(wave_b, grid_point, tangent, binormal);
	p += gerstner_wave(wave_c, grid_point, tangent, binormal);
	
	vec3 normal = normalize(cross(binormal, tangent));
	VERTEX = p;
	NORMAL = normal;
}

void fragment() {
	// Depth Calculation
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	float z_depth = linear_depth + VERTEX.z; 
	
	// Beer's Law (Depth Absorption)
	float depth_attenuation = exp(-z_depth * beer_law_factor);
	depth_attenuation = clamp(1.0 - depth_attenuation, 0.0, 1.0);
	
	// Edge Foam
	float foam_edge = clamp(1.0 - (z_depth / edge_scale), 0.0, 1.0);
	
	// Wave Peak Foam
	float foam_peak = clamp((1.0 - NORMAL.y) * 4.0, 0.0, 1.0);
	foam_peak = pow(foam_peak, 4.0); // Sharper foam
	
	// Mask foam by noise to break it up
	float foam_noise = texture(noise_tex, UV * 10.0 + TIME * 0.1).r;
	float total_foam = clamp((foam_edge + foam_peak) * foam_noise, 0.0, 1.0);
	
	// Color Mixing
	vec3 water_color = mix(albedo, albedo_deep, depth_attenuation);
	vec3 final_color = mix(water_color, foam_color.rgb, total_foam);
	
	ALBEDO = final_color;
	METALLIC = metallic;
	ROUGHNESS = mix(roughness, 0.8, total_foam); 
	
	// Refraction
	vec2 distort = NORMAL.xz * 0.02;
	vec3 screen_color = texture(screen_texture, SCREEN_UV + distort).rgb;
	
	// Fix White-out: Fresnel usually adds white at edges.
	// We manually darken the albedo based on viewing angle to simulate deep water absorption
	float view_dot = dot(NORMAL, VIEW); // 1.0 = straight on, 0.0 = edge
	
	// Transmission (Alpha)
	ALPHA = clamp(0.85 + depth_attenuation * 0.15, 0.0, 1.0);
}
