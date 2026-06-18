extends CharacterBody2D

const GRAVITY = 980.0
const MAX_HEALTH = 500.0
const CHASE_SPEED = 350.0
const CHARGE_SPEED = 550.0
const IDLE_RANGE = 200.0
const MELEE_RANGE = 90.0
const CHARGE_RANGE = 300.0
const DETECTION_RANGE = 500.0
const MELEE_DAMAGE = 15.0
const CHARGE_DAMAGE = 25.0

@onready var animated_sprite = $Wearwolf
@onready var hitbox = $Hitbox

var player = null
var health = MAX_HEALTH
var is_dead = false
var is_attacking = false
var is_charging = false
var is_engaged = false
var charge_direction = 0

var attack_cooldown = 0.0
var charge_cooldown = 0.0
var attack_timer = 0.0

func _ready():
	add_to_group("wolf")
	player = get_tree().get_first_node_in_group("player")
	hitbox.monitoring = false
	animated_sprite.animation_finished.connect(_on_animation_finished)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	animated_sprite.play("Idle")
	_update_health_bar()

func _update_health_bar():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_wolf_health(health)

func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		var damage = CHARGE_DAMAGE if is_charging else MELEE_DAMAGE
		body.take_damage(damage)

func take_damage(amount):
	if is_dead:
		return
	health -= amount
	health = max(health, 0.0)
	_update_health_bar()
	print("Wolf health: ", health)
	if health <= 0:
		die()

func die():
	is_dead = true
	hitbox.monitoring = false
	velocity = Vector2.ZERO
	animated_sprite.play("Dead")
	print("Wolf defeated!")

func _on_animation_finished():
	if is_dead:
		return
	is_attacking = false
	is_charging = false
	hitbox.monitoring = false
	velocity.x = 0
	attack_timer = 0.0

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if player == null:
		move_and_slide()
		return

	# Fallback timer
	if is_attacking or is_charging:
		attack_timer += delta
		if attack_timer > 1.5:
			is_attacking = false
			is_charging = false
			hitbox.monitoring = false
			velocity.x = 0
			attack_timer = 0.0

	attack_cooldown = max(attack_cooldown - delta, 0.0)
	charge_cooldown = max(charge_cooldown - delta, 0.0)

	var distance = global_position.distance_to(player.global_position)
	var direction = sign(player.global_position.x - global_position.x)
	var player_is_blocking = player.is_blocking
	var player_is_attacking = player.is_attacking
	var player_is_airborne = not player.is_on_floor()

	# Engage when player gets close
	if not is_engaged and distance <= IDLE_RANGE:
		is_engaged = true

	if not is_engaged:
		velocity.x = 0
		_play("Idle")
		move_and_slide()
		return

	# Always face player
	animated_sprite.flip_h = direction < 0

	if is_attacking:
		velocity.x = 0

	elif is_charging:
		velocity.x = charge_direction * CHARGE_SPEED
		if distance <= MELEE_RANGE or is_on_wall():
			is_charging = false
			hitbox.monitoring = false
			velocity.x = 0
			charge_cooldown = 2.0

	else:
		var best_action = _pick_best_action(distance, player_is_blocking, player_is_attacking, player_is_airborne)

		match best_action:
			"melee_1":
				_do_attack("Attack_1")
			"melee_2":
				_do_attack("Attack_2")
			"melee_3":
				_do_attack("Attack_3")
			"charge":
				_do_charge(direction)
			"chase":
				if distance > MELEE_RANGE + 20.0:
					velocity.x = direction * CHASE_SPEED
				else:
					velocity.x = 0
				_play("Run")
			"idle":
				velocity.x = 0
				_play("Idle")

	move_and_slide()

func _pick_best_action(distance, player_blocking, player_attacking, player_airborne) -> String:
	var scores = {}

	if attack_cooldown == 0.0 and distance <= MELEE_RANGE:
		scores["melee_1"] = 80.0
		scores["melee_2"] = 60.0 + (40.0 if player_attacking else 0.0)
		scores["melee_3"] = 50.0 + (60.0 if player_blocking else 0.0)

	if charge_cooldown == 0.0 and distance > MELEE_RANGE and distance <= CHARGE_RANGE:
		scores["charge"] = 70.0
		scores["charge"] += 30.0 if player_airborne else 0.0
		scores["charge"] -= 20.0 if player_blocking else 0.0

	if distance > MELEE_RANGE and distance <= DETECTION_RANGE:
		scores["chase"] = 50.0
		scores["chase"] += 30.0 if distance < CHARGE_RANGE * 0.5 else 0.0

	if distance > DETECTION_RANGE:
		scores["idle"] = 100.0

	if scores.is_empty():
		return "idle"

	var best = "idle"
	var best_score = -1.0
	for action in scores:
		if scores[action] > best_score:
			best_score = scores[action]
			best = action

	return best

func _do_attack(anim_name):
	is_attacking = true
	hitbox.monitoring = true
	velocity.x = 0
	attack_cooldown = 0.8
	attack_timer = 0.0
	_play(anim_name)

func _do_charge(direction):
	is_charging = true
	hitbox.monitoring = true
	charge_direction = direction
	velocity.x = charge_direction * CHARGE_SPEED
	charge_cooldown = 2.0
	attack_timer = 0.0
	_play("Run_Attack")

func _play(anim_name):
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
