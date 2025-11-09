extends Node2D

@onready var tv_on: Sprite2D = $TvOn
@onready var tv_off: Sprite2D = $TvOff
@onready var tv_ram: Sprite2D = $Tv_ram
@onready var tv_area: Area2D = $Tv_ram/Area2D

# Logo bouncing variables
var logo: Sprite2D
var logo_velocity: Vector2 = Vector2(16, 14)  # Speed in pixels per second
var area_bounds: Rect2

# Space to start variables
var space_to_start: Sprite2D
var blink_timer: float = 0.0
var blink_interval: float = 1.0
var is_space_visible: bool = true
var can_start_game: bool = false

var flicker_count: int = 0
var max_flickers: int = 4
var flicker_timer: float = 0.0
var flicker_interval: float = 0.5
var is_tv_on: bool = false

# Zoom variables
var initial_scale: Vector2
var target_scale: Vector2
var total_animation_time: float
var initial_position: Vector2
var zoom_target_y: float = 160.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start with TV off
	tv_on.visible = false
	tv_off.visible = true
	is_tv_on = false
	
	# Set up zoom animation
	initial_scale = tv_on.scale  # Both sprites should have the same initial scale
	target_scale = initial_scale * 1.9
	initial_position = tv_on.position  # Store initial position
	total_animation_time = (max_flickers + 1) * flicker_interval  # Total time for flickers + final wait

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Check for jump input to start game
	if can_start_game and Input.is_action_just_pressed("jump"):
		switch_to_game()
		return
	
	# Update zoom animation
	update_zoom(delta)
	
	# Update bouncing logo
	update_bouncing_logo(delta)
	
	# Update blinking space to start
	update_space_to_start_blink(delta)
	
	if flicker_count < max_flickers:
		flicker_timer += delta
		
		if flicker_timer >= flicker_interval:
			flicker_timer = 0.0
			toggle_tv()
			flicker_count += 1
	elif flicker_count == max_flickers:
		# After flickers, wait a moment then turn off both TVs
		flicker_timer += delta
		if flicker_timer >= flicker_interval:
			turn_off_tv()

func toggle_tv():
	is_tv_on = !is_tv_on
	tv_on.visible = is_tv_on
	tv_off.visible = !is_tv_on
	
	# Reset logo when TV turns off
	if not is_tv_on:
		setup_bouncing_logo()
		setup_space_to_start()

func update_zoom(delta: float):
	# Calculate current time elapsed
	var current_time = (flicker_count * flicker_interval) + flicker_timer
	
	# Calculate zoom progress (0.0 to 1.0)
	var zoom_progress = clamp(current_time / total_animation_time, 0.0, 1.0)
	
	# Smoothly interpolate between initial and target scale
	var current_scale = initial_scale.lerp(target_scale, zoom_progress)
	
	# Calculate position offset to zoom into y=200
	# As we zoom in, we need to move the sprite up to keep y=200 centered
	var scale_factor = current_scale.y / initial_scale.y
	var y_offset = (initial_position.y - zoom_target_y) * (scale_factor - 1.0)
	var target_position = Vector2(initial_position.x, initial_position.y - y_offset)
	
	# Apply the scale and position to all TV sprites
	tv_on.scale = current_scale
	tv_off.scale = current_scale
	tv_ram.scale = current_scale
	tv_on.position = target_position
	tv_off.position = target_position
	tv_ram.position = target_position

func turn_off_tv():
	# Turn off both TV sprites (black screen)
	tv_on.visible = false
	tv_off.visible = false

func setup_bouncing_logo():
	# Remove existing logo if it exists
	if logo:
		logo.queue_free()
	
	# Create the logo sprite programmatically
	logo = Sprite2D.new()
	logo.texture = preload("res://img/logo.png")
	logo.scale = Vector2(0.02, 0.02)  # Make it much smaller to fit in the TV screen
	logo.z_index = -1  # Render behind the tv_ram
	
	# Add the logo to the TV area
	tv_area.add_child(logo)
	
	# Get the collision shape to determine bounds
	var collision_shape = tv_area.get_child(0) as CollisionShape2D
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape = collision_shape.shape as RectangleShape2D
		var shape_size = rect_shape.size
		var shape_position = collision_shape.position
		
		# Adjust bounds to be smaller and more centered (reduce width, increase height)
		var adjusted_width = shape_size.x * 0.72 
		var adjusted_height = shape_size.y * 0.98  
		var offset_y = shape_size.y * 0.0 
		
		# Set bounds relative to the collision shape with adjustments
		area_bounds = Rect2(
			shape_position.x - adjusted_width/2, 
			shape_position.y - adjusted_height/2 + offset_y, 
			adjusted_width, 
			adjusted_height
		)
		
		# Log the dimensions for debugging
		print("Original shape size: ", shape_size)
		print("Shape position: ", shape_position)
		print("Adjusted bounds: ", area_bounds)
		print("Adjusted width: ", adjusted_width, " height: ", adjusted_height)
	else:
		# Fallback bounds if no collision shape found
		area_bounds = Rect2(-35, -15, 70, 35)
		print("Using fallback bounds: ", area_bounds)
	
	# Start logo at a random position within bounds
	logo.position = Vector2(
		randf_range(area_bounds.position.x + 10, area_bounds.position.x + area_bounds.size.x - 10),
		randf_range(area_bounds.position.y + 10, area_bounds.position.y + area_bounds.size.y - 10)
	)

func update_bouncing_logo(delta: float):
	if not logo:
		return
	
	# Move the logo at normal speed (don't divide by scale factor)
	logo.position += logo_velocity * delta
	
	# Get logo bounds - these need to be adjusted for the current scale
	var logo_half_width = 2  # Reduced since logo is smaller now
	var logo_half_height = 2  # Reduced since logo is smaller now
	
	# Use the original area bounds (before scaling)
	var effective_bounds = area_bounds
	
	# Check for collisions with area bounds and bounce
	if logo.position.x - logo_half_width <= effective_bounds.position.x or logo.position.x + logo_half_width >= effective_bounds.position.x + effective_bounds.size.x:
		logo_velocity.x = -logo_velocity.x
		# Keep logo within bounds
		logo.position.x = clamp(logo.position.x, effective_bounds.position.x + logo_half_width, effective_bounds.position.x + effective_bounds.size.x - logo_half_width)
	
	if logo.position.y - logo_half_height <= effective_bounds.position.y or logo.position.y + logo_half_height >= effective_bounds.position.y + effective_bounds.size.y:
		logo_velocity.y = -logo_velocity.y
		# Keep logo within bounds
		logo.position.y = clamp(logo.position.y, effective_bounds.position.y + logo_half_height, effective_bounds.position.y + effective_bounds.size.y - logo_half_height)

func setup_space_to_start():
	# Remove existing space_to_start if it exists
	if space_to_start:
		space_to_start.queue_free()
	
	# Create the space to start sprite
	space_to_start = Sprite2D.new()
	space_to_start.texture = preload("res://img/space_to_start.png")
	
	# Position it inside the bouncing area (bottom center of the rect)
	var center_x = area_bounds.position.x + area_bounds.size.x / 2
	var bottom_y = area_bounds.position.y + area_bounds.size.y - 2
	space_to_start.position = Vector2(center_x, bottom_y)
	
	space_to_start.scale = Vector2(0.014, 0.014)
	space_to_start.z_index = -1  # Same as logo, render behind tv_ram
	
	# Add to the TV area (same as logo)
	tv_area.add_child(space_to_start)
	
	# Reset blink state
	is_space_visible = true
	blink_timer = 0.0
	
	# Enable game starting
	can_start_game = true

func update_space_to_start_blink(delta: float):
	if not space_to_start:
		return
	
	# Update blink timer
	blink_timer += delta
	
	# Check if we should toggle visibility
	if blink_timer >= blink_interval:
		blink_timer = 0.0
		is_space_visible = !is_space_visible
		space_to_start.visible = is_space_visible

func switch_to_game():
	# Switch to the main game scene
	get_tree().change_scene_to_file("res://game.tscn")
