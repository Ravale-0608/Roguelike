extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -650.0
const ROLL_SPEED = 220.0
const DOUBLE_TAP_TIME = 0.3
const HEAVY_ATTACK_HOLD_TIME = 0.4

@onready var animated_sprite = $AnimatedSprite2D

var is_attacking = false
var is_heavy_attacking = false
var is_blocking = false
var is_rolling = false
var attack_finished = false

var last_tap_right = 0.0
var last_tap_left = 0.0
var air_direction = 0
var attack_hold_timer = 0.0
var jump_attack_done = false

func _ready():
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.animation_changed.connect(_on_animation_changed)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.speed_scale = 1.5

func _on_animation_finished():
	if is_attacking or is_heavy_attacking:
		is_attacking = false
		is_heavy_attacking = false
		attack_finished = true
		jump_attack_done = false
	if is_rolling:
		is_rolling = false

func _on_animation_changed():
	if animated_sprite.animation == "Jump" or animated_sprite.animation == "Upward Jump":
		animated_sprite.speed_scale = 3.0
	elif animated_sprite.animation in ["Attack", "Heavy Attack", "Jumping Slash", "Air Attack"]:
		animated_sprite.speed_scale = 2.5
	else:
		animated_sprite.speed_scale = 1.5

func _on_frame_changed():
	if (animated_sprite.animation == "Jump" or animated_sprite.animation == "Upward Jump") and animated_sprite.frame >= 2:
		animated_sprite.speed_scale = 1.5

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("Move_Left", "Move_Right")

	# Reset air direction on landing
	if is_on_floor():
		air_direction = 0
		jump_attack_done = false
		attack_hold_timer = 0.0

	# Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_rolling:
		velocity.y = JUMP_VELOCITY
		air_direction = int(direction)

	# Track attack hold time on ground only
	if Input.is_action_pressed("Attack") and not attack_finished and not is_blocking and not is_rolling and is_on_floor():
		attack_hold_timer += delta
	elif is_on_floor() and not Input.is_action_pressed("Attack"):
		attack_hold_timer = 0.0

	# Reset attack_finished when button released
	if not Input.is_action_pressed("Attack"):
		attack_finished = false

	# Ground attack on button release
	if is_on_floor() and not is_blocking and not is_rolling and not attack_finished and not is_attacking and not is_heavy_attacking:
		if Input.is_action_just_released("Attack"):
			if attack_hold_timer >= HEAVY_ATTACK_HOLD_TIME:
				is_heavy_attacking = true
			else:
				is_attacking = true
			attack_hold_timer = 0.0

	# Air attack on button press
	if not is_on_floor() and not jump_attack_done and not attack_finished and not is_attacking:
		if Input.is_action_just_pressed("Attack"):
			is_attacking = true
			jump_attack_done = true

	# Block — ground only
	if not is_rolling and is_on_floor():
		is_blocking = Input.is_action_pressed("Block")
	else:
		is_blocking = false

	# Double tap to roll
	if not is_attacking and not is_heavy_attacking and not is_blocking and not is_rolling and is_on_floor():
		if Input.is_action_just_pressed("Move_Right"):
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_tap_right < DOUBLE_TAP_TIME:
				is_rolling = true
			last_tap_right = current_time

		if Input.is_action_just_pressed("Move_Left"):
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_tap_left < DOUBLE_TAP_TIME:
				is_rolling = true
			last_tap_left = current_time

	# Flip sprite — locked in air, during roll, during attack, during ground block
	if is_on_floor() and not is_attacking and not is_heavy_attacking and not (is_blocking and is_on_floor()) and not is_rolling:
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true

	# Animations
	var new_animation = ""
	if is_rolling:
		new_animation = "Roll"
	elif is_heavy_attacking:
		new_animation = "Heavy Attack"
	elif is_attacking:
		if not is_on_floor():
			if air_direction != 0:
				new_animation = "Jumping Slash"
			else:
				new_animation = "Air Attack"
		else:
			new_animation = "Attack"
	elif is_blocking:
		new_animation = "Block"
	elif not is_on_floor():
		if air_direction == 0:
			new_animation = "Upward Jump"
		else:
			new_animation = "Jump"
	elif direction != 0:
		new_animation = "Run"
	else:
		new_animation = "Idle"

	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)

	# Movement
	if is_rolling:
		velocity.x = ROLL_SPEED * (-1 if animated_sprite.flip_h else 1)
	elif (is_attacking or is_heavy_attacking or is_blocking) and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif not is_on_floor():
		if air_direction != 0:
			velocity.x = air_direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
