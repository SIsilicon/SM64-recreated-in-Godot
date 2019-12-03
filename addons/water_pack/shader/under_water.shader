shader_type canvas_item;

uniform float blur : hint_range(0,10);
uniform float fade_depth = 20;//0~FLOAT_MAX
uniform float distort_factor : hint_range(0,1);
uniform float distort_speed : hint_range(0,1);
uniform sampler2D distort_texture : hint_normal;
uniform vec4 water_color : hint_color ;//= vec4(20, 30, 30, 230);
uniform bool distort_enable = true;


varying vec2 zoom;
varying float depth;

void vertex() {
	zoom = vec2(WORLD_MATRIX[0].x, WORLD_MATRIX[1].y);
	depth = VERTEX.y;
}

void fragment(){
	vec2 uv = SCREEN_UV;
	
	if(distort_enable) {
		vec2 distort = texture(distort_texture, UV + TIME * distort_speed).rg * 2.0 - 1.0;
		uv += distort * distort_factor * zoom;
	}
	
	COLOR = textureLod(SCREEN_TEXTURE, uv, blur);
	
	if(fade_depth > 0.0) {
		COLOR.rgb = mix(COLOR.rgb, water_color.rgb, min(depth / fade_depth, 1.0) * water_color.a);
	}
}
