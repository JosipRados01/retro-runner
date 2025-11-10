extends Node2D

# List of tilemap scenes to use for procedural generation
@export var tilemap_scenes: Array[PackedScene] = []

# Reference to the player
@onready var player: CharacterBody2D = $player
@onready var camera: Camera2D = $player/Camera2D

# Generation settings
@export var section_width: float = 480.0  # Width of each tile section
@export var generation_distance: float = 1000.0  # Distance ahead to generate
@export var cleanup_distance: float = 1000.0  # Distance behind to cleanup
@export var ground_level: float = 616.0  # Y position where ground should be
@export var death_y: float = 800.0  # Y position where player dies (falls off screen)

# Camera settings
@export var camera_follow_speed: float = 9.0  # How fast camera follows player vertically
@export var camera_y_min: float = 200.0  # Top boundary for camera panning
@export var camera_y_max: float = 700.0  # Bottom boundary for camera panning
@export var camera_vertical_range: float = 200.0  # How much the camera can pan up/down

# Tracking variables
var active_sections: Array[Node2D] = []
var next_spawn_x: float = -400.0
var last_player_x: float = 0.0

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
	print("Player died! Reloading scene...")
	reset_game()

func reset_game():
	# Reload the current scene completely
	get_tree().reload_current_scene()

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
