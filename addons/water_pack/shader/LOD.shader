shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;

//uniforms for waves
uniform sampler2D waves;
uniform sampler2D noise;
uniform sampler2D foam;
uniform vec4 noise_params = vec4(0,1,1,1);
/*This uniform contains data that changes noise.
X- The amplitude of the noise.
Y- The frequency of the noise.
Z- The propagation speed of the noise.
W- Whether to use noise. Values greater than 0 means yes.
*/
uniform float foam_strength;
uniform float time_offset;

//uniforms for lod management
uniform uint morph_levels;
uniform float lod_scale;
uniform uint level;
uniform uint resolution;

//LOD FUNCTIONS
vec2 compute_ancestor_morphing(int lv, vec2 grid_pos, float height_morph_fac, vec3 camera_scaled_pos, float res, vec2 prev_morphing) {
	vec2 fractional_part = grid_pos * res * 0.5;
	if(lv > 1) fractional_part = (fractional_part + 0.5) / pow(2.0, float(lv - 1));
	
	fractional_part -= floor(fractional_part);
	
	vec2 square_offset = abs(camera_scaled_pos.xz - (grid_pos + prev_morphing)) / float(lv);
	vec2 compare_pos = max(vec2(0), square_offset * 4.0 - 1.0);
	float parent_morph_factor = min(1.0, max(compare_pos.x, compare_pos.y));
	
	vec2 morph_factor = vec2(0);
	if((fractional_part.x + fractional_part.y) > 0.49) {
		float morphing = parent_morph_factor;
		if((int(level) + lv) == 1)
			morphing = max(height_morph_fac, morphing);
		morph_factor += morphing * floor(fractional_part * 2.0);
	}
	return float(lv) * morph_factor / res;
}
vec4 compute_position(vec4 position, mat4 cam_matrix) {
	vec3 camera_position = -cam_matrix[3].xyz * mat3(cam_matrix[0].xyz, cam_matrix[1].xyz, cam_matrix[2].xyz);
	
	float res = float(resolution);
	
	vec3 projected_camera = vec3(camera_position.x, 0.0, camera_position.z);
	
	float camera_height_log = max( 0.1, log2(distance(camera_position, projected_camera)));
	float loc_scale = lod_scale * pow(2.0, floor(camera_height_log)) * 0.005;
	vec3 camera_scaled_position = projected_camera / loc_scale;
	vec2 grid_position = position.xz + floor(camera_scaled_position.xz * res + 0.5) / res;
	
	float height_morph_factor = camera_height_log - floor(camera_height_log);
	
	highp vec2 morphing = vec2(0);
	for(int i = 1; i < 2; ++i) {
		if(i <= int(morph_levels))
			morphing += compute_ancestor_morphing(i, grid_position, height_morph_factor, camera_scaled_position, res, morphing);
	}
	grid_position = grid_position + morphing;
	
	vec3 world_position = vec3(grid_position.x, 0, grid_position.y) * loc_scale;
	
	return vec4(world_position, 1.0);
}

//NOISE FUNCTION WITH RESPECTIVE HELPERS
float cubic(float c0, float p0, float p1, float c1, float t) {
	float t2 = t*t;
	float t3 = t2*t;
	return (t3-t2-t+1.0)*p0 + (t3-2.0*t2+t)*c0 + (t3-t2)*c1 + (-3.0*t3+4.0*t2)*p1;
}
float noise3D(vec3 p) {
	float iz = floor(p.z);
	float fz = fract(p.z);
	
	vec2 offset = vec2(0.356, 0.879) * 0.64338;
	
	float a = texture(noise, p.xy + offset * iz).r;
	float b = texture(noise, p.xy + offset * (iz+1.0)).r;
	float ca = texture(noise, p.xy + offset * (iz-1.0)).r;
	float cb = texture(noise, p.xy + offset * (iz+2.0)).r;
	
	return cubic(ca, a, b, cb, fz);
}
float perlin(vec2 pos, float time) {
	float p_noise = 2.0 * noise3D(vec3(pos.xy*noise_params.y, time*noise_params.z))*noise_params.x - 1.0;
	return p_noise + 2.0 * noise3D(vec3(pos.xy*noise_params.y*2.0, time*noise_params.z+4.3))*noise_params.x/2.0 - 1.0;
}

//WAVE FUNCTIONS
vec3 wave(vec2 pos, float time, bool use_noise) {
	highp vec3 new_p = vec3(pos.x, 0.0, pos.y);
	
	highp float amp, w, steep, phase;
	highp vec2 dir;
	for(int i = 0; i < textureSize(waves, 0).y; i++) {
		amp = texelFetch(waves, ivec2(0, i), 0).r;
		
		dir = vec2(texelFetch(waves, ivec2(2, i), 0).r, texelFetch(waves, ivec2(3, i), 0).r);
		w = texelFetch(waves, ivec2(4, i), 0).r;
		steep = texelFetch(waves, ivec2(1, i), 0).r /(w*amp);
		phase = 2.0 * w;
		
		float W = dot(w*dir, pos) + phase*time;
		
		new_p.xz += steep*amp * dir * cos(W);
		new_p.y += amp * sin(W);
	}
	new_p += perlin(pos, time);
	
	return new_p;
}
vec3 wave_normal(vec2 pos, float time, float res) {
	vec3 wave_norm = vec3(0,1,0);
	
	float amp, w, steep, phase;
	vec2 dir;
	for(int i = 0; i < textureSize(waves, 0).y; i++) {
		amp = texelFetch(waves, ivec2(0, i), 0).r;
		
		dir = vec2(texelFetch(waves, ivec2(2, i), 0).r, texelFetch(waves, ivec2(3, i), 0).r);
		w = texelFetch(waves, ivec2(4, i), 0).r;
		steep = texelFetch(waves, ivec2(1, i), 0).r /(w*amp);
		phase = 2.0 * w;
		
		float W = dot(w*dir, pos) + phase*time;
		
		wave_norm.xz -= dir * w*amp * cos(W);
		wave_norm.y -= steep * w*amp * sin(W);
	}
	
	vec2 _res = vec2(res,0);
	
	vec3 right = vec3(pos.xy + _res.xy, perlin(pos + _res.xy, time)).xzy;
	vec3 left = vec3(pos.xy - _res.xy, perlin(pos - _res.xy, time)).xzy;
	vec3 down = vec3(pos.xy + _res.yx, perlin(pos + _res.yx, time)).xzy;
	vec3 up = vec3(pos.xy - _res.yx, perlin(pos - _res.yx, time)).xzy;
	vec3 noise_norm = bool(noise_params.w) ? normalize(cross(right-left, down-up)) : vec3(0,1,0);
	
	vec3 new_norm = vec3(wave_norm.xz + noise_norm.xz, wave_norm.y);
	
	return normalize(new_norm).xzy;
}

//FRESNEL FUNCTION
float fresnel(float n1, float n2, float cos_theta) {
	float R0 = pow((n1 - n2) / (n1+n2), 2);
	float fres = R0 + (1.0 - R0)*pow(1.0 - abs(cos_theta), 5);
	
	float critical_angle = asin(n1 / n2);
	if(acos(abs(cos_theta)) > critical_angle && sign(cos_theta) == -1.0) return 1.0;
	
	return fres;
}

varying vec3 vert_coord;
varying float vert_dist;

varying vec3 eyeVector;

void vertex() {
	//compute LOD position
	VERTEX = compute_position(vec4(VERTEX, 0.0), INV_CAMERA_MATRIX).xyz;
	
	//compute offset by wave
	VERTEX = wave(VERTEX.xz, time_offset, false);
	
	//pass varyings and transform vertex in view space
	vert_coord = VERTEX;
	VERTEX = (INV_CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	eyeVector = (CAMERA_MATRIX * vec4(normalize(VERTEX), 0.0)).xyz;
	vert_dist = length(VERTEX);
}

void fragment() {
	//calculate normals based on wave
	NORMAL = wave_normal(vert_coord.xz, time_offset, vert_dist/40.0);
	
	//calculate reflectiveness based on fresnel and camera angle
	float eye_dot_norm = -dot(eyeVector, NORMAL);
	float n1 = 1.0, n2 = 1.3333;
	float reflectiveness = fresnel(n1, n2, eye_dot_norm);
	
	vec3 water_colour = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 fog_colour = vec3(0, 0.05, 0.1);
	float density = 0.1; //cannot be zero. :/
	
	//calculate refraction with fog
	float depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
	world_pos.xyz /= world_pos.w;
	water_colour = mix(fog_colour, water_colour, clamp(smoothstep(world_pos.z+1.0/density, world_pos.z, VERTEX.z), 0.0, 1.0));
	
	
	ROUGHNESS = 0.0;
	METALLIC = reflectiveness;
	ALBEDO = vec3(reflectiveness);
	
	EMISSION = water_colour * (1.0 - reflectiveness);
	
	//apply foam
	EMISSION += texture(foam, vert_coord.xz/20.0).rgb * (1.0 - NORMAL.y)*foam_strength;
	
	//transform normal to view space for lighting
	NORMAL = (INV_CAMERA_MATRIX * vec4(NORMAL, 0.0)).xyz;
}