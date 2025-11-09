extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect the body_entered signal to handle player collision
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Check if the colliding body is the player
	if body.name == "player" and body is CharacterBody2D:
		var player = body as CharacterBody2D
		# Bounce player upward with the same speed they were falling
		var bounce_speed = - min(max(abs(player.velocity.y), 400 ), 700 ) # Make it negative (upward)
		player.velocity.y = bounce_speed
		
		# Trigger screenshake for stomp
		if player.has_method("trigger_stomp_shake"):
			player.trigger_stomp_shake()
		
		# Optional: Reset jump state so player can control the bounce
		if player.has_method("reset_jump_state"):
			player.reset_jump_state()
		
		print("Player bounced with velocity: ", bounce_speed)
