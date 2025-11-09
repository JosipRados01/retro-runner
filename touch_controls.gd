extends Control

# Touch control script for tablet/mobile gameplay
# This script creates virtual buttons that trigger the custom input actions

var stomp_button: TouchScreenButton  
var speed_button: TouchScreenButton

func _ready():
	# Set up the control to cover the full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Only show touch controls on mobile devices
	if is_mobile_platform():
		create_stomp_button()
		create_speed_button()
		print("Touch controls enabled for mobile platform")
	else:
		print("Touch controls disabled - desktop platform detected")

func create_stomp_button():
	# Create stomp button (left side, bottom)
	stomp_button = TouchScreenButton.new()
	stomp_button.name = "StompButton" 
	stomp_button.action = "stomp"
	
	# Position on bottom left - responsive to screen size
	var screen_size = get_viewport().get_visible_rect().size
	stomp_button.position = Vector2(20, screen_size.y - 120)
	
	# Create visual representation
	var stomp_texture = create_button_texture("STOMP", Color.RED, Vector2(120, 100))
	stomp_button.texture_normal = stomp_texture
	stomp_button.texture_pressed = create_button_texture("STOMP", Color.DARK_RED, Vector2(120, 100))
	
	add_child(stomp_button)

func create_speed_button():
	# Create speed button (right side) - now handles both jump and speed
	speed_button = TouchScreenButton.new()
	speed_button.name = "SpeedButton"
	speed_button.action = "jump"
	
	# Position on right side - aligned better with the red button
	var screen_size = get_viewport().get_visible_rect().size
	speed_button.position = Vector2(screen_size.x - 170, screen_size.y - 120)
	
	# Create visual representation - same size as red button
	var speed_texture = create_button_texture("JUMP & SPEED", Color.BLUE, Vector2(120, 100))
	speed_button.texture_normal = speed_texture
	speed_button.texture_pressed = create_button_texture("JUMP & SPEED", Color.DARK_BLUE, Vector2(120, 100))
	
	add_child(speed_button)

func is_mobile_platform() -> bool:
	# Use Godot's built-in feature detection for reliable mobile detection
	
	# Check for mobile feature flag (works for native mobile builds)
	if OS.has_feature("mobile"):
		return true
	
	# For web builds, check specific mobile browser features first
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true

	# For any other platform (desktop), hide controls
	return false

func create_button_texture(text: String, color: Color, button_size: Vector2) -> ImageTexture:
	# Create a simple colored rectangle with text for button visualization
	var width = int(button_size.x)
	var height = int(button_size.y)
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Fill with semi-transparent color for better visibility
	var transparent_color = Color(color.r, color.g, color.b, 0.7)
	image.fill(transparent_color)
	
	# Add simple border
	var border_color = Color.WHITE
	var border_width = 3
	for x in range(width):
		for y in range(height):
			if x < border_width or x >= width - border_width or y < border_width or y >= height - border_width:
				image.set_pixel(x, y, border_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture
