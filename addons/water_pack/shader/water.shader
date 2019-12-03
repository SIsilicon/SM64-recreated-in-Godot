shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
//render_mode unshaded; //test
// todo optimiz

uniform float TIME;
uniform vec4 water_color : hint_color ;//= vec4(20, 30, 30, 230);
uniform float roughness : hint_range(0, 1) ;//= 0.1;
uniform float metalness : hint_range(0, 1); //= 0.6;
uniform float specular : hint_range(0, 1); //= 0.1;

// normal map wave
uniform sampler2D normal_map1:hint_normal;
uniform float normal1_scale : hint_range(0, 1); //= 0.0;
uniform vec2 normal1_velocity = vec2(0.01, 0);
uniform vec2 normal1_uv_scale = vec2(10, 10);

uniform sampler2D normal_map2:hint_normal;
uniform float normal2_scale : hint_range(0, 1); //= 0.0;
uniform vec2 normal2_velocity = vec2(0.01, 0);
uniform vec2 normal2_uv_scale = vec2(10, 10);

uniform uint WITHOUT_TRANSPRANT = 0;
uniform uint ALBEDO_ALPHA_TRANSPRANT = 1;
uniform uint SIMPLE_FADE_TRANSPRANT = 2;
uniform uint REFRACT_TRANSPRANT = 3;
uniform uint transprant_mode = 3; //todo replace with enum alfter godot 3.1

uniform uint FAKE_REFRACT_OFFSET_DEPTH = 0;
uniform uint FAKE_REFRACT_LINE_DEPTH = 1;
uniform uint refract_method = 1; //todo replace with enum alfter godot 3.1
uniform float refraction : hint_range(0, 10); //= .1;
uniform float fade_distance = 1;

uniform uint PLANAR_REFLECT = 0;
uniform uint SKYMAP_REFLECT = 1;
uniform uint reflection_mode = 1;
uniform sampler2D reflect_texture : hint_black;
uniform float reflection : hint_range(0, 10); //= .1;

uniform float eta : hint_range(0, 1); //= 0.6;
uniform float fresnel_power = 6.0;

uniform sampler2D foam_texture : hint_white;
uniform float foam_uv_scale = 5.0;
uniform vec4 foam_color : hint_color ;//= vec4(1,1,1,0);
uniform float foam_depth_factor : hint_range(0, 10);  //= 0.2; //depth 
uniform vec2 foam_wave_factor = vec2(0.0,1.0); // wave higt range 

varying smooth vec3 vertex_offset;
varying smooth vec3 vertex_nrml;

//Gerstner wave4
uniform bool gerstner_wave4_enable = true;
uniform float gerstner_factor = 1;
uniform vec4 wave4_amplitude;
uniform vec4 wave4_frequency;
uniform vec4 wave4_steepness;
uniform vec4 wave4_speed;
uniform vec4 wave4_direction12;
uniform vec4 wave4_direction34;


float fresnel (vec3 v, vec3 n)
{
	float F = ((1.0 - eta) * (1.0 - eta)) / ((1.0 + eta) * (1.0 + eta));
	float ratio = F + (1.0 - F) * pow(1.0 - dot(v, n), fresnel_power);
	return ratio;
}

vec3 mix_normals(vec3 normal1, float scale1, vec3 normal2, float scale2)
{
	vec3 n1 = normal1 * 2.0 - 1.0;
	vec3 n2 = normal2 * 2.0 - 1.0;
	vec3 normal = normalize(vec3(n1.xy * scale1 + n2.xy * scale2, n1.z * n2.z));
	return normal * 0.5 + 0.5;
}

void fragment()
{
	
    ROUGHNESS = roughness;
    METALLIC = metalness;
    SPECULAR = specular;
    //	RIM = 0.1;
    //	RIM_TINT = 0.7;
	
    // normal wave
    vec2 uv1 = mod(normal1_uv_scale * UV + TIME * normal1_velocity, 1);
    vec3 normal1 = texture(normal_map1, uv1).rgb;
    vec2 uv2 = mod(normal2_uv_scale * UV + TIME * normal2_velocity, 1);
    vec3 normal2 = texture(normal_map2, uv2).rgb;
    NORMALMAP = mix_normals(normal1, normal1_scale, normal2, normal2_scale);
	NORMALMAP_DEPTH = 1.0;
    ALBEDO = water_color.rgb;
	vec3 view_nrml = normalize( mix(NORMAL,TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL * NORMALMAP.z,NORMALMAP_DEPTH) );
	// transprant
    vec3 refract_color = vec3(0, 0, 0);
    if (transprant_mode == SIMPLE_FADE_TRANSPRANT)
    {
        float depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
        vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
        world_pos.xyz /= world_pos.w;
        ALPHA *= clamp(1.0 - smoothstep(world_pos.z + fade_distance, world_pos.z, VERTEX.z), 0.0, 1.0);
    }
    else if (transprant_mode == REFRACT_TRANSPRANT)
    {
        // fake refraction
        if (refract_method == FAKE_REFRACT_OFFSET_DEPTH)
        {
    		vec2 screen_offset = view_nrml.xy * refraction/VERTEX.z;
            float depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV + screen_offset).r;
            vec4 world_pos = INV_PROJECTION_MATRIX * vec4((SCREEN_UV + screen_offset) * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
            world_pos.xyz /= world_pos.w;
            float depth = distance(VERTEX.xyz, world_pos.xyz);
            if ((depth < fade_distance))
            {
                float factor = clamp(1.0 - depth / fade_distance, 0.0, 1.0);
				refract_color = textureLod(SCREEN_TEXTURE, SCREEN_UV + screen_offset * depth, ROUGHNESS).rgb * factor;
                //fix edge
//                float line_depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
//                vec4 line_world_pos = INV_PROJECTION_MATRIX * vec4((SCREEN_UV)*2.0 - 1.0, line_depth_tex * 2.0 - 1.0, 1.0);
//                line_world_pos.xyz /= line_world_pos.w;
//                float linedepth=VERTEX.z-line_world_pos.z;
////                float linedepth = distance(VERTEX.xyz, line_world_pos.xyz);
//                if ((depth > 0.0) || (linedepth > 0.0))
//                {
//                    refract_color = textureLod(SCREEN_TEXTURE, SCREEN_UV + screen_offset * depth, ROUGHNESS).rgb * factor;
//                }
            }
        }
        else if (refract_method == FAKE_REFRACT_LINE_DEPTH)
        {
            float depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
            vec4 world_pos = INV_PROJECTION_MATRIX * vec4((SCREEN_UV)*2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
            world_pos.xyz /= world_pos.w;
			float depth=VERTEX.z-world_pos.z;
            if ((depth < fade_distance))
            {
        		vec2 screen_offset = view_nrml.xy * refraction/VERTEX.z* depth;
                float factor = clamp(1.0 - depth / fade_distance, 0.0, 1.0);
                refract_color = textureLod(SCREEN_TEXTURE, SCREEN_UV + screen_offset, ROUGHNESS).rgb * factor;
                //fix edge
                float real_depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV + screen_offset).r;
                vec4 real_world_pos = INV_PROJECTION_MATRIX * vec4((SCREEN_UV + screen_offset) * 2.0 - 1.0, real_depth_tex * 2.0 - 1.0, 1.0);
                real_world_pos.xyz /= real_world_pos.w;
                float realDepth = distance(VERTEX.xyz, real_world_pos.xyz);
                if (realDepth > fade_distance)
                {
                    refract_color = vec3(0, 0, 0);
                }
            }
        }
        ALPHA = 1.0;
    }
    else if(transprant_mode == ALBEDO_ALPHA_TRANSPRANT)
    {
        ALPHA = water_color.a;
    }
	
    //reflection
	vec3 reflect_color = vec3(0, 0, 0);
	if(reflection_mode == PLANAR_REFLECT){
    	reflect_color = textureLod(reflect_texture, SCREEN_UV + view_nrml.xy * reflection / VERTEX.z, ROUGHNESS).rgb;	
	}
	else if(reflection_mode == SKYMAP_REFLECT){
//		uniform cubemap reflect_map;
//		NORMAL = normalize( NORMAL );
//		VAR1 = normalize(MODELVIEW_MATRIX * vec4(VERTEX.x,VERTEX.y,VERTEX.z,1.0));
//		vec3 n_reflection = normalize(reflect(vec3(VAR1.x,VAR1.y,VAR1.z), NORMAL));
//		vec4 cor = texcube(reflect_map, n_reflection );
	}

    //fresnel
	float ratio = fresnel(normalize(-VERTEX), NORMAL);
    EMISSION = mix(refract_color, reflect_color, ratio);

	//foam
    // fake depth foam
    if(foam_depth_factor !=0.0){
        float depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
        vec4 world_pos = INV_PROJECTION_MATRIX * vec4((SCREEN_UV) * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
        world_pos.xyz /= world_pos.w;
        float depth = VERTEX.z-world_pos.z;
        if ((depth < foam_depth_factor))
        {
//			ALBEDO = mix(ALBEDO,foam_color.rgb,foam_color.a*depth); // simple with foam_color
            float foam_amount = 1.0-smoothstep(0, foam_depth_factor, depth);
			foam_amount =foam_amount*smoothstep(-0.2, .2, vertex_offset.y);
			vec2 foam_uv = foam_uv_scale *5.0* UV;
	        vec2 foam_col=texture(foam_texture, foam_uv).ra;
	        ALBEDO = mix(ALBEDO,foam_col.x* foam_color.rgb,foam_col.y*foam_amount);

        }
    }
	if(gerstner_wave4_enable == true)	//wave foam
	{
		vec2 foam_uv = foam_uv_scale * UV;
		float foam_amount = smoothstep(foam_wave_factor.x, foam_wave_factor.y, vertex_offset.y);
        vec2 foam_col=texture(foam_texture, foam_uv).ra;
        vec2 foam_col2=texture(foam_texture, foam_uv+.3).ra;
        ALBEDO = mix(ALBEDO,foam_col.x* foam_color.rgb,foam_col.y*foam_amount);
        ALBEDO = mix(ALBEDO,foam_col2.x* foam_color.rgb,foam_col2.y*foam_amount);
	}
}

vec3 gerstner_offset(vec2 vtx_xz, float steepness, float amp, float freq, float speed, vec2 dir)
{
    vec3 offsets;
    offsets.x =
        steepness * amp * dir.x *
        cos(freq * dot(dir, vtx_xz) + speed * TIME);
    offsets.z =
        steepness * amp * dir.y *
        cos(freq * dot(dir, vtx_xz) + speed * TIME);
    offsets.y =
        amp * sin(freq * dot(dir, vtx_xz) + speed * TIME);
    return offsets;
}
vec3 gerstner_offset4(vec2 vtx_xz, vec4 steepness, vec4 amp, vec4 freq, vec4 speed, vec4 dir_12, vec4 dir_34)
{
    vec3 offsets;
    vec4 AB = steepness.xxyy * amp.xxyy * dir_12.xyzw;
    vec4 CD = steepness.zzww * amp.zzww * dir_34.xyzw;
    vec4 dotABCD = freq.xyzw * vec4(dot(dir_12.xy, vtx_xz), dot(dir_12.zw, vtx_xz), dot(dir_34.xy, vtx_xz), dot(dir_34.zw, vtx_xz));
    vec4 COS = cos(dotABCD + TIME * speed);
    vec4 SIN = sin(dotABCD + TIME * speed);

    offsets.x = dot(COS, vec4(AB.xz, CD.xz));
    offsets.z = dot(COS, vec4(AB.yw, CD.yw));
    offsets.y = dot(SIN, amp);

    return offsets;
}
vec3 gerstner_normal(vec2 vtx_xz, float amp, float freq, float speed, vec2 dir)
{
    vec3 nrml = vec3(0, 0, 0);
    nrml.x -=
        dir.x * (amp * freq) *
        cos(freq * dot(dir, vtx_xz) + speed * TIME);
    nrml.z -=
        dir.y * (amp * freq) *
        cos(freq * dot(dir, vtx_xz) + speed * TIME);
    return nrml;
}

vec3 gerstner_normal4(vec2 vtx_xz, vec4 amp, vec4 freq, vec4 speed, vec4 dir_12, vec4 dir_34)
{
    vec3 nrml = vec3(0, 2.0, 0);

    vec4 AB = freq.xxyy * amp.xxyy * dir_12.xyzw;
    vec4 CD = freq.zzww * amp.zzww * dir_34.xyzw;

    vec4 dotABCD = freq.xyzw * vec4(dot(dir_12.xy, vtx_xz), dot(dir_12.zw, vtx_xz), dot(dir_34.xy, vtx_xz), dot(dir_34.zw, vtx_xz));

    vec4 COS = cos(dotABCD + TIME * speed);

    nrml.x -= dot(COS, vec4(AB.xz, CD.xz));
    nrml.z -= dot(COS, vec4(AB.yw, CD.yw));

    nrml.xz *= gerstner_factor;
    nrml = normalize(nrml);

    return nrml;
}

void vertex()
{
    if (gerstner_wave4_enable)
    {
        vertex_offset = gerstner_offset4(VERTEX.xz, wave4_steepness, wave4_amplitude, wave4_frequency, wave4_speed, wave4_direction12, wave4_direction34);
        vertex_nrml = gerstner_normal4(VERTEX.xz, wave4_amplitude, wave4_frequency, wave4_speed, wave4_direction12, wave4_direction34);
        VERTEX = VERTEX + vertex_offset;
        NORMAL = vertex_nrml;
    }
}
