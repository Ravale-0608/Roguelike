shader_type canvas_item;

// Noise texture
uniform sampler2D noise_texture: repeat_enable, filter_nearest;

// Fod desntiy 
uniform float density: hint_range(0.0, 1.0) = 0.25;

//fog speed
uniform vec2 speed = vec2(0.02, 0.01);

void fragment() {
	// fog slowly moves
	vec2 uv = UV + speed * TIME;
	// Sample the noise texture
	float noise = texture(noise_texture, uv).r;
	
	
	// Convert the nouse from (0.0, 1.0) range to the (-1.0, 1.0) range
	float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);
	//APPLY the fog effect
	COLOR.a *= fog * density;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
