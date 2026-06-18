extends GPUParticles2D

func _ready():
	amount = 8
	lifetime = 30.0
	emitting = true
	preprocess = 30.0
	one_shot = false
	visibility_rect = Rect2(-600, -400, 1200, 800)
	
	var material = ParticleProcessMaterial.new()
	
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(600, 30, 0)
	material.direction = Vector3(1, 0, 0)
	material.spread = 5.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 4.0
	material.gravity = Vector3(0, 0, 0)
	material.scale_min = 50.0
	material.scale_max = 120.0
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.519, 0.592, 0.71, 0.0))
	gradient.add_point(0.2, Color(0.5, 0.6, 0.7, 0.02))
	gradient.add_point(0.5, Color(0.5, 0.6, 0.7, 0.02))
	gradient.add_point(0.8, Color(0.5, 0.6, 0.7, 0.02))
	gradient.add_point(1.0, Color(0.5, 0.6, 0.7, 0.0))
	
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	material.color_ramp = color_ramp
	process_material = material

	# Better soft circle — larger image, smoother falloff
	var size = 128
	var half = size / 2.0
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for x in range(size):
		for y in range(size):
			var dx = (x - half) / half
			var dy = (y - half) / half
			var dist = sqrt(dx * dx + dy * dy)
			# Smooth falloff — fully transparent at edges
			var alpha = clamp(1.0 - dist, 0.0, 1.0)
			alpha = pow(alpha, 2.5)  # stronger power = softer edges
			# Only set alpha if inside the circle
			if dist >= 1.0:
				image.set_pixel(x, y, Color(1, 1, 1, 0.0))
			else:
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	var texture = ImageTexture.create_from_image(image)
	self.texture = texture
