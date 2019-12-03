shader_type canvas_item;
uniform vec4 water_color: hint_color;
uniform sampler2D noise_texture: hint_white;
uniform float amplitudo = 0.015;
uniform float speed = 2.0;
uniform vec2 scale = vec2(1,1);
uniform float distort_factor = .05; // 0 disable distort
uniform float distort_speed = .1;

void fragment()
{
    vec2 uv = UV*scale;    
    vec2 displacement = texture(noise_texture, uv/6.0).xy;
    float t = uv.y + displacement.y * 0.1 - 0.15 + (sin (uv.x * 60.0+TIME*speed) * amplitudo);
    COLOR = texture(TEXTURE, vec2(uv.x, t)).rgba;
    COLOR = COLOR* water_color;
    //distort
    if(distort_factor!=0.0){
    	vec2 distortion = distort_factor*(texture(noise_texture,UV+TIME*distort_speed).rg * 2.0 - 1.0);
        if(COLOR.a!=0.0){
        	vec3 col = textureLod(SCREEN_TEXTURE, SCREEN_UV+distortion, 1.0).rgb;
            COLOR.rgb = mix(col.rgb,COLOR.rgb,COLOR.a);
            COLOR.a = 1.0;
        }  
    }
}