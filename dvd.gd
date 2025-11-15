extends Node2D

const POINTS = 200

var hover_tween: Tween
var original_position: Vector2

func _ready():
	# Store original position for hovering animation
	original_position = position
	
	# Connect the area entered signal to detect player collision
	$Area2D.body_entered.connect(_on_body_entered)
	
	start_hover_animation()

func start_hover_animation():
	# Create tween for hovering animation
	hover_tween = create_tween()
	hover_tween.set_loops()  # Loop infinitely
	
	# Animate up and down with different timing than disketa
	var hover_distance = 10.0  # Slightly more movement for DVD
	var hover_duration = 2.5   # Slightly different timing
	
	# Move up
	hover_tween.tween_property(self, "position", original_position + Vector2(0, -hover_distance), hover_duration / 2)
	# Move down
	hover_tween.tween_property(self, "position", original_position + Vector2(0, hover_distance), hover_duration / 2)
	# Return to original
	hover_tween.tween_property(self, "position", original_position, hover_duration / 2)

func _on_body_entered(body):
	# Check if the body that entered is the player
	if body.name == "player":
		# Stop the hovering animation
		if hover_tween:
			hover_tween.kill()
		
		# Play pickup sound effect
		MusicManager.play_pickup_sound()
		
		# Add points to the score system
		ScoreSystem.add_collectible_points(POINTS)
		print("DVD collected! +", POINTS, " points")
		
		# Remove the collectible from the scene
		queue_free()
