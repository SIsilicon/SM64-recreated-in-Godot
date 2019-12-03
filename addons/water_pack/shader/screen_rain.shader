shader_type canvas_item;
//from https://www.shadertoy.com/view/ltffzl

uniform vec2 rain_amount_range = vec2(0.3,0.7); //0~1
uniform vec2 max_blur_range = vec2(3.0, 6.0);
uniform float min_blur :hint_range(0,10); // = 2.0;  
uniform float screen_zoom :hint_range(0,1); // = 1;
uniform float rain_speed :hint_range(0,1); // = 1 ;
uniform bool USE_LIGHTNING;
uniform bool USE_CHEAP_NORMALS;

vec3 N13(float p) {
	//  from DAVE HOSKINS
	vec3 p3 = fract(vec3(p) * vec3(.1031,.11369,.13787));
	p3 += dot(p3, p3.yzx + 19.19);
	return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

vec4 N14(float t) {
	return fract(sin(t*vec4(123.0, 1024.0, 1456.0, 264.0))*vec4(6547.0, 345.0, 8799.0, 1564.0));
}
float N(float t) {
	return fract(sin(t*12345.564)*7658.76);
}

float Saw(float b, float t) {
	return smoothstep(0.0, b, t)*smoothstep(1.0, b, t);
}


vec2 drop_layer2(vec2 uv, float t) {
	vec2 uva = uv;
	
	uv.y += t*0.75;
	vec2 a = vec2(6.0, 1.0);
	vec2 grid = a*2.0;
	vec2 id = floor(uv*grid);
	
	float colShift = N(id.x); 
	uv.y += colShift;
	
	id = floor(uv*grid);
	vec3 n = N13(id.x*35.2+id.y*2376.1);
	vec2 st = fract(uv*grid)-vec2(.5, 0);
	
	float x = n.x-.5;
	
	float y = uva.y*20.0;
	float wiggle = sin(y+sin(y));
	x += wiggle*(0.5-abs(x))*(n.z-0.5);
	x *= 0.7;
	float ti = fract(t+n.z);
	y = (Saw(0.85, ti)-0.5)*0.9+0.5;
	vec2 p = vec2(x, y);
	
	float d = length((st-p)*a.yx);
	
	float main_drop = smoothstep(.4, .0, d);
	
	float r = sqrt(smoothstep(1.0, y, st.y));
	float cd = abs(st.x-x);
	float trail = smoothstep(.23*r, .15*r*r, cd);
	float trail_front = smoothstep(-.02, .02, st.y-y);
	trail *= trail_front*r*r;
	
	y = uva.y;
	float trail2 = smoothstep(.2*r, .0, cd);
	float droplets = max(0.0, (sin(y*(1.0-y)*120.0)-st.y))*trail2*trail_front*n.z;
	y = fract(y*10.0)+(st.y-.5);
	float dd = length(st-vec2(x, y));
	droplets = smoothstep(.3, 0.0, dd);
	float m = main_drop+droplets*r*trail_front;
	
	//m += st.x>a.y*.45 || st.y>a.x*.165 ? 1.2 : 0.0;
	return vec2(m, trail);
}

float static_drops(vec2 uv, float t) {
	uv *= 40.0;
	
	vec2 id = floor(uv);
	uv = fract(uv)-.5;
	vec3 n = N13(id.x*107.45+id.y*3543.654);
	vec2 p = (n.xy-.5)*.7;
	float d = length(uv-p);
	
	float fade = Saw(.025, fract(t+n.z));
	float c = smoothstep(.3, 0.0, d)*fract(n.z*10.0)*fade;
	return c;
}

vec2 drops(vec2 uv, float t, float l0, float l1, float l2) {
	float s = static_drops(uv, t)*l0; 
	vec2 m1 = drop_layer2(uv, t)*l1;
	vec2 m2 = drop_layer2(uv*1.85, t)*l2;
	
	float c = s+m1.x+m2.x;
	c = smoothstep(.3, 1.0, c);
	
	return vec2(c, max(m1.y*l0, m2.y*l1));
}

void fragment() {
	vec2 uv1 = vec2((SCREEN_UV.x-0.5)*SCREEN_PIXEL_SIZE.x/SCREEN_PIXEL_SIZE.y,SCREEN_UV.y-0.5);
	vec2 uv2 = SCREEN_UV;
	float t = TIME*rain_speed;  
	float rain_amount =sin(TIME*.01)*(rain_amount_range.y-rain_amount_range.x)+rain_amount_range.x;    
	float max_blur = mix(max_blur_range.x, max_blur_range.y, rain_amount);
	float story = 0.0;
	uv1 *= .7+screen_zoom*.3;
	uv2 = (uv2-.5)*(.9+screen_zoom*.1)+.5;
	
	float static_drops = smoothstep(-0.5, 1.0, rain_amount)*2.0;
	float layer1 = smoothstep(0.25, 0.75, rain_amount);
	float layer2 = smoothstep(0.0, 0.5, rain_amount);
	
	vec2 c = drops(uv1, t, static_drops, layer1, layer2);
	vec2 n ;
	if(USE_CHEAP_NORMALS){
		n = vec2(dFdx(c.x), dFdy(c.x)); // cheap normals (3x cheaper, but 2 times worse)
	} else {
		vec2 e = vec2(.001, 0.0);
		float cx = drops(uv1+e, t, static_drops, layer1, layer2).x;
		float cy = drops(uv1+e.yx, t, static_drops, layer1, layer2).x;
		n = vec2(cx-c.x, cy-c.x);		// expensive normals
	}
	       
	float focus = mix(max_blur-c.y, min_blur, smoothstep(.1, .2, c.x));
	vec3 col = textureLod(SCREEN_TEXTURE, uv2+n, focus).rgb;
	col = textureLod(SCREEN_TEXTURE, UV, 0.0).rgb;
	
	if(USE_LIGHTNING){
		t = (TIME+3.0)*.5;
		float col_fade = sin(t*.2)*.5+.5+story;
		col *= mix(vec3(1.0), vec3(.8, .9, 1.3), col_fade); // subtle color shift
		float fade = smoothstep(0.0, 10.0, TIME); // fade in at the start
		float lightning = sin(t*sin(t*10.0)); // lighting flicker
		lightning *= pow(max(0.0, sin(t+sin(t))), 10.0); // lightning flash
		col *= 1.0+lightning*fade*mix(1.0, 0.1, story*story); // composite lightning
		col *= 1.0-dot(uv2-=.5, uv2);
		col *= fade; // composite start and end fade    
	}
	
	COLOR = vec4(col, 1.0);
}