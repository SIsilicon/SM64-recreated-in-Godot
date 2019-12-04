extends Entity

var lifetime := -1.0
var intangible_buffer = 5

func _ready():
	if lifetime > 0:
		velocity.y = randf() * 10.0 + 30.0
		forward_velocity = randf() * 10.0
		move_angle_yaw = randf() * 2*PI

func _process(delta : float) -> void:
	if lifetime > 0:
		update_floor_and_walls()
	
	move_standard(-1.08)
	
	if intangible_buffer == 0:
		$CollisionShape.disabled = false
	else:
		intangible_buffer -= 1
	
	$Coin.rotation.y += 0.2

func _on_body_entered(body : Node) -> void:
	if not Engine.editor_hint:
		if body is Mario:
			Global.coin_counter += 1
			
			queue_free()