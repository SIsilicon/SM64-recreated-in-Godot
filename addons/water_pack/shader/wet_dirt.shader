shader_type spatial;

uniform sampler2D dirt_tex;
uniform float dirt_scale = 3.0;

uniform sampler2D wet_map;
uniform float wet_map_strength = 1.0;
uniform float wet_map_bias = 0.0;
uniform bool invert_wet_map = true;

uniform sampler2D wave: hint_normal;
uniform vec2 wind_dir1 = vec2(0.1, 0.0);
uniform vec2 wind_dir2 = vec2(-0.1, 0.0);
uniform float wave_size1 = 4.0;
uniform float wave_size2 = 4.0;
uniform float wave_strength;

vec3 mix_normals(vec3 normal1, vec3 normal2) {
	vec3 n1 = normal1 * 2.0 - 1.0;
	vec3 n2 = normal2 * 2.0 - 1.0;
	vec3 normal = normalize(vec3(n1.xy * wave_size1 + n2.xy * wave_size2, n1.z * n2.z));
	return normal * 0.5 + 0.5;
}

void fragment() {
	vec2 uv1 = mod(wave_size1 * UV + TIME * wind_dir1, 1);
	vec3 normal1 = texture(wave, uv1).rgb;
	vec2 uv2 = mod(wave_size2 * UV + TIME * wind_dir2, 1);
	vec3 normal2 = texture(wave, uv2).rgb;
	
	NORMALMAP = mix_normals(normal1, normal2);
	NORMALMAP_DEPTH = wave_strength;
	
	float wetness = invert_wet_map ? 1.0-texture(wet_map, UV).r : texture(wet_map, UV).r;
	wetness = wet_map_strength * (wetness - wet_map_bias);
	wetness = clamp(wetness, 0.0, 1.0);
	
	vec3 dirt_color = texture(dirt_tex, UV*dirt_scale).rgb;
	float dirt_darkness = mix(-1.0, 1.0, wetness);
	
	ROUGHNESS = 1.0 - wetness;
	METALLIC = wetness;
	
	ALBEDO = mix(dirt_color, vec3(dirt_darkness), wetness);
}