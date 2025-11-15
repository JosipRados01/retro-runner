extends Node2D

# List of tilemap scenes to use for procedural generation
@export var tilemap_scenes: Array[PackedScene] = []

# Reference to the player
@onready var player: CharacterBody2D = $player
@onready var camera: Camera2D = $player/Camera2D
@onready var score_label: Label = $UILayer/ScoreUI/ScoreLabel
@onready var highscore_label: Label = $UILayer/ScoreUI/HighScoreLabel
@onready var combo_label: Label = $UILayer/ScoreUI/ComboLabel

# Animation variables
var combo_tween: Tween
var combo_original_position: Vector2

# Score system reference (assuming it's set as a global/autoload)
var score_system

# Generation settings
@export var section_width: float = 480.0  # Width of each tile section
@export var generation_distance: float = 1000.0  # Distance ahead to generate
@export var cleanup_distance: float = 1000.0  # Distance behind to cleanup
@export var ground_level: float = 616.0  # Y position where ground should be
@export var death_y: float = 800.0  # Y position where player dies (falls off screen)

# Camera settings
@export var camera_follow_speed: float = 9.0  # How fast camera follows player vertically
@export var camera_y_min: float = 300.0  # Top boundary for camera panning
@export var camera_y_max: float = 800.0  # Bottom boundary for camera panning
@export var camera_vertical_range: float = 200.0  # How much the camera can pan up/down

# Tracking variables
var active_sections: Array[Node2D] = []
var next_spawn_x: float = -400.0
var last_player_x: float = 0.0

# Difficulty progression variables
var game_time: float = 0.0
var basic_scenes_removed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load tilemap scenes if not assigned in editor
	if tilemap_scenes.is_empty():
		var grass_scene = preload("res://10grass.tscn")
		var gap_scene = preload("res://grass_gap.tscn")
		var big_gap_scene = preload("res://grass_big_gap.tscn")
		var early_gap_scene = preload("res://early gap.tscn")
		var two_small_gaps_scene = preload("res://grass_two_small_gaps.tscn")
		#var enemy_bounce_scene = preload("res://enemy_bounce.tscn")
		var low_bounce_scene = preload("res://low_bounce.tscn")
		var double_low_jump_scene = preload("res://double_low_jump.tscn")
		var single_bounce_scene = preload("res://single_bounce.tscn")
		
		tilemap_scenes.append(grass_scene)
		tilemap_scenes.append(gap_scene)
		tilemap_scenes.append(big_gap_scene)
		tilemap_scenes.append(early_gap_scene)
		tilemap_scenes.append(two_small_gaps_scene)
		#tilemap_scenes.append(enemy_bounce_scene)
		tilemap_scenes.append(low_bounce_scene)
		tilemap_scenes.append(double_low_jump_scene)
		tilemap_scenes.append(single_bounce_scene)
	
	# Set initial spawn position based on existing tilemaps
	calculate_initial_spawn_position()
	
	# Generate initial sections
	generate_initial_sections()
	
	# Initialize score system
	setup_score_system()

	# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update game time and check for difficulty progression
	game_time += delta
	if not basic_scenes_removed and game_time >= 60.0:  # 1 minute
		remove_basic_scenes()
		basic_scenes_removed = true
		print("Difficulty progression: Basic scenes removed for easier combos!")
	
	if player:
		var player_x = player.global_position.x
		var player_y = player.global_position.y
		
		# Update camera based on player Y position
		update_camera_position(player_y, delta)
		
		# Check if player has fallen off the screen (death condition)
		if player_y > death_y:
			player_died()
			return
		
		# Check if we need to generate new sections
		if player_x > next_spawn_x - generation_distance:
			generate_next_section()
		
		# Cleanup old sections
		cleanup_old_sections(player_x)
		
		last_player_x = player_x

func calculate_initial_spawn_position():
	# Find the rightmost existing tilemap to know where to start spawning
	var rightmost_x = 0.0
	for child in get_children():
		if child is TileMapLayer:
			var tilemap_right = child.global_position.x + get_tilemap_width(child)
			if tilemap_right > rightmost_x:
				rightmost_x = tilemap_right
				next_spawn_x = rightmost_x

func get_tilemap_width(tilemap: TileMapLayer) -> float:
	# Calculate approximate width based on tile data
	# This is a simple estimation - you might want to make this more precise
	return section_width

func generate_initial_sections():
	# Always start with 3 basic grass platforms for a safe beginning
	var grass_scene = preload("res://10grass.tscn")
	for i in range(3):
		generate_specific_section(grass_scene)
	
	# Then generate additional random sections
	for i in range(2):  # Generate 2 more random sections ahead
		generate_next_section()

func generate_next_section():
	if tilemap_scenes.is_empty():
		return
	
	# Pick a random tilemap scene
	var random_scene = tilemap_scenes[randi() % tilemap_scenes.size()]
	generate_specific_section(random_scene)

func generate_specific_section(scene: PackedScene):
	# Instance the specified scene
	var new_section = scene.instantiate()
	
	# Position it at the next spawn location
	new_section.global_position.x = next_spawn_x
	new_section.global_position.y = ground_level
	
	# Set z_index to render in front of player and parallax foreground
	new_section.z_index = 200
	
	# Add to scene
	add_child(new_section)
	
	# Track the section
	active_sections.append(new_section)
	
	# Update next spawn position
	next_spawn_x += section_width
	
	print("Generated new section at x: ", new_section.global_position.x)

func cleanup_old_sections(player_x: float):
	# Remove sections that are too far behind the player
	var sections_to_remove = []
	
	for section in active_sections:
		var section_right = section.global_position.x + section_width
		if section_right < player_x - cleanup_distance:
			sections_to_remove.append(section)
	
	# Remove old sections
	for section in sections_to_remove:
		active_sections.erase(section)
		section.queue_free()
		print("Cleaned up section at x: ", section.global_position.x)

func player_died():
	print("Player died! Final score: ", ScoreSystem.get_score())
	
	# Play death sound effect through music manager
	MusicManager.play_death_sound()
	
	reset_game()

func reset_game():
	# Reset score system before reloading
	ScoreSystem.reset_score()
	
	# Reload the current scene completely
	get_tree().reload_current_scene()

func setup_score_system():
	# Get reference to the global score system
	score_system = ScoreSystem
	
	if score_system:
		# Set the player reference in the score system
		score_system.set_player(player)
		
		# Connect to score signals if you want to update UI
		score_system.score_changed.connect(_on_score_changed)
		score_system.distance_changed.connect(_on_distance_changed)
		score_system.highscore_changed.connect(_on_highscore_changed)
		score_system.combo_changed.connect(_on_combo_changed)
		
		# Initialize the score displays
		_on_score_changed(score_system.get_score())
		_on_highscore_changed(score_system.get_highscore())
		_on_combo_changed(score_system.get_combo_count(), score_system.get_combo_points())
		
		# Store original combo label position for shake animation
		if combo_label:
			combo_original_position = combo_label.position
		
		print("Score system connected successfully")
	else:
		print("Warning: Score system not found as global/autoload")

func _on_score_changed(new_score: int):
	print("Score updated: ", new_score)
	# Update the score label with SCORE: prefix and actual number (no padding)
	if score_label:
		score_label.text = "SCORE: " + str(new_score)

func _on_highscore_changed(new_highscore: int):
	print("High score updated: ", new_highscore)
	# Update the high score label with HIGH: prefix and actual number (no padding)
	if highscore_label:
		highscore_label.text = "HIGHSCORE: " + str(new_highscore)

func _on_combo_changed(combo_count: int, combo_points: int):
	# Update the combo label
	if combo_label:
		if combo_count > 0:
			combo_label.text = "COMBO x" + str(combo_count) + " (" + str(combo_points) + " pts)"
			# Animate the combo label when combo increases
			animate_combo_label(combo_count)
		else:
			combo_label.text = ""

func _on_distance_changed(new_distance: float):
	# You can use this to update distance display if needed
	pass

func remove_basic_scenes():
	# Remove basic scenes that don't have duck bounces to make combos easier
	var scenes_to_remove = []
	
	for scene in tilemap_scenes:
		var scene_path = scene.resource_path
		if "10grass.tscn" in scene_path or "grass_gap.tscn" in scene_path or "grass_two_small_gaps.tscn" in scene_path:
			scenes_to_remove.append(scene)
	
	for scene in scenes_to_remove:
		tilemap_scenes.erase(scene)
		print("Removed scene: ", scene.resource_path)
	
	print("Basic scenes removed. Remaining scenes: ", tilemap_scenes.size())

func update_camera_position(player_y: float, delta: float):
	if not camera:
		return
	
	# Calculate target camera Y offset based on player position
	# Map player Y position (0 to 800) to camera offset range
	var normalized_y = clamp((player_y - camera_y_min) / (camera_y_max - camera_y_min), 0.0, 1.0)
	
	# When player is near y=0 (higher up), camera should pan down (positive offset)
	# When player is near y=800 (lower down), camera should pan up (negative offset)
	var target_y_offset = lerp(camera_vertical_range, -camera_vertical_range, normalized_y)
	
	# Smoothly interpolate to the target offset
	var current_offset = camera.offset
	current_offset.y = lerp(current_offset.y, target_y_offset, camera_follow_speed * delta)
	camera.offset = current_offset

func animate_combo_label(combo_count: int):
	if not combo_label:
		return
	
	# Kill existing tween if running
	if combo_tween:
		combo_tween.kill()
	
	# Create new tween
	combo_tween = create_tween()
	combo_tween.set_parallel(true)  # Allow multiple animations at once
	
	# Calculate scale based on combo count - bigger combos = bigger scale
	var base_scale = 1.0
	var max_scale = base_scale + (0.15 * combo_count )  # Increases by 0.15 per combo
	max_scale = min(max_scale, 2.0)  # Cap at 2.0 to prevent too large scaling
	
	# Scale animation: scale up based on combo count, then back to base
	var scale_up_duration = 0.04 + (combo_count * 0.02)  # Slightly longer animation for bigger combos
	var scale_down_duration = 0.15 + (combo_count * 0.03)
	
	# Calculate position offset to keep scaling centered
	# When scaling, the label grows from top-left, so we need to offset it back to center
	var label_size = combo_label.size
	var scale_offset = Vector2(
		(label_size.x * (max_scale - 1.0)) * -0.5,  # Move left by half the extra width
		(label_size.y * (max_scale - 1.0)) * -0.5   # Move up by half the extra height
	)
	var scaled_position = combo_original_position + scale_offset
	
	# Animate scale and position together for centered scaling
	combo_tween.tween_property(combo_label, "scale", Vector2(max_scale, max_scale), scale_up_duration)
	combo_tween.tween_property(combo_label, "position", scaled_position, scale_up_duration)
	
	# Scale back down and return to original position
	combo_tween.tween_property(combo_label, "scale", Vector2(base_scale, base_scale), scale_down_duration).set_delay(scale_up_duration)
	combo_tween.tween_property(combo_label, "position", combo_original_position, scale_down_duration).set_delay(scale_up_duration)
