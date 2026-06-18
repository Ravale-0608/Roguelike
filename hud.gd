extends CanvasLayer

@onready var player_health_bar = $Control/Hamlet
@onready var wolf_health_bar = $Control/Wearwolf

func _ready():
	add_to_group("hud")
	print("HUD ready, player bar: ", player_health_bar)
	print("HUD ready, wolf bar: ", wolf_health_bar)
	player_health_bar.max_value = 150.0
	player_health_bar.value = 150.0
	wolf_health_bar.max_value = 500.0
	wolf_health_bar.value = 500.0
	print("Player bar value: ", player_health_bar.value)
	print("Wolf bar value: ", wolf_health_bar.value)

func update_player_health(amount):
	print("Updating player health to: ", amount)
	player_health_bar.value = amount

func update_wolf_health(amount):
	print("Updating wolf health to: ", amount)
	wolf_health_bar.value = amount
