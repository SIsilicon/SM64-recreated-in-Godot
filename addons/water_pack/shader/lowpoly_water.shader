shader_type spatial;
render_mode skip_vertex_transform, cull_disabled, world_vertex_coords;

uniform sampler2D reflect_texture;
uniform bool use_planar_reflect;

uniform sampler2D wave_bump: hint_black;

uniform float time; //using a custom time uniform to sync shader with script

uniform sampler2D foam_tex;
uniform float foam_strength = 0.25;

uniform vec2 wave_dir1;
uniform vec2 wave_dir2;
uniform vec2 wave_dir3;
uniform float frequency = 0.1;
uniform float amplitude = 0.3;

uniform float density = 1.0;
uniform vec4 color: hint_color;

varying vec3 vert_coord;
varying float vert_dist;
varying vec3 eye_vector;

void vertex() {
	
	vec2 uv = VERTEX.xz * frequency / 10.0;
	float height = texture(wave_bump, uv - time * wave_dir1).r * 2.0 - 1.0;
	height += texture(wave_bump, (uv + 0.25) - time * wave_dir2).g * 2.0 - 1.0;
	height += texture(wave_bump, (uv - 0.25) - time * wave_dir3).b * 2.0 - 1.0;
	height *= amplitude;
	
	VERTEX.y += height;
	
	//pass varyings and transform vertex in view space
	vert_coord = VERTEX;
	VERTEX = (INV_CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	eye_vector = (CAMERA_MATRIX * vec4(normalize(VERTEX), 0.0)).xyz;
	vert_dist = length(VERTEX);
}

//FRESNEL FUNCTION
float fresnel(float n1, float n2, float cos_theta) {
	float R0 = pow((n1 - n2) / (n1+n2), 2);
	float fres = R0 + (1.0 - R0)*pow(1.0 - abs(cos_theta), 5);
	
	float critical_angle = asin(n1 / n2);
	if(acos(abs(cos_theta)) > critical_angle && sign(cos_theta) == 1.0) return 1.0;
	
	return fres;
}

//function from https://gamedev.stackexchange.com/questions/92015/optimized-linear-to-srgb-glsl
vec4 to_linear(vec4 sRGB) {
	bvec4 cutoff = lessThan(sRGB, vec4(0.04045));
	vec4 higher = pow((sRGB + vec4(0.055))/vec4(1.055), vec4(2.4));
	vec4 lower = sRGB/vec4(12.92);
	
	return mix(higher, lower, cutoff);
}

void fragment() {
	//The following line of code makes the water look flat-shaded.
	NORMAL = cross(dFdx(VERTEX), dFdy(VERTEX));
	NORMAL = normalize(NORMAL) * (2.0 * float(FRONT_FACING) - 1.0);
	NORMAL = (inverse(INV_CAMERA_MATRIX) * vec4(NORMAL, 0.0)).xyz;
	
	//calculate reflectiveness based on fresnel and camera angle
	float eye_dot_norm = dot(eye_vector, NORMAL);
	float n1 = 1.0, n2 = 1.3333;
	float reflectiveness = fresnel(n1, n2, eye_dot_norm);
	
	vec2 distort_uv = SCREEN_UV - NORMAL.xz*0.05;
	vec3 water_color = texture(SCREEN_TEXTURE, distort_uv).rgb;
	vec4 fog_color = color;
	
	//calculate refraction with fog
	float depth_tex = texture(DEPTH_TEXTURE, distort_uv).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(distort_uv * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
	world_pos.xyz /= world_pos.w;
	fog_color.a = clamp(1.0 - exp(-(VERTEX.z - world_pos.z) * density), 0.0, 1.0);
	water_color = mix(water_color, fog_color.rgb, fog_color.a * float(FRONT_FACING));
	
	//calculate foam
	depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
	world_pos.xyz /= world_pos.w;
	float foam = clamp(foam_strength - (VERTEX.z - world_pos.z), 0.0, 1.0) / foam_strength;
	foam = smoothstep(0.0, 1.0, foam);
	foam *= texture(foam_tex, 0.5 * vert_coord.xz + 2.0 * time).r;
	
	//calculate planar reflection(if there is one)
	vec4 reflect_color = to_linear(texture(reflect_texture, distort_uv));
	reflect_color = use_planar_reflect ? reflect_color : vec4(0.0);
	
	ROUGHNESS = reflect_color.a;
	METALLIC = reflectiveness * (1.0-reflect_color.a);
	ALBEDO = vec3(METALLIC);
	EMISSION = mix(water_color, reflect_color.rgb, reflectiveness) + smoothstep(0.4-0.01, 0.4+0.01, foam);
	
	//transform normal to view space for lighting
	NORMAL = (INV_CAMERA_MATRIX * WORLD_MATRIX * vec4(NORMAL, 0.0)).xyz;
	ALPHA = 1.0;
}

void light() {
	DIFFUSE_LIGHT = vec3(0);
}