extends CharacterBody2D

const SPEED = 300.0
const MIN_JUMP_VELOCITY = -200.0  # Tiny jump when just tapping
const MAX_JUMP_VELOCITY = -700.0  # Very big jump when holding
const MAX_JUMP_TIME = 0.3  # How long you can hold to reach max jump
const JUMP_BOOST_FORCE = -1500.0  # Very strong additional force applied while holding
const JUMP_BOOST_DELAY = 0.03  # Small delay before boost starts
const COYOTE_TIME = 0.15  # Time after leaving ground where player can still jump
const FAST_FALL_MULTIPLIER = 4.0  # How much faster to fall when slowing down

@export var auto_run: bool = false  # Enable automatic running
var auto_run_timer: float = 0.0  # Timer for auto run delay
const AUTO_RUN_DELAY: float = 1  # Delay before auto run starts

# Jump variables
var is_jumping = false
var jump_time = 0.0
var has_jumped = false  # Prevents double jumping

# Coyote time variables
var coyote_timer = 0.0
var was_on_floor = false
var was_on_floor_last_frame = false  # For combo landing detection

# Stomp variables
var is_stomping = false
var disable_y_restart = false  # Prevents y restart after balloon bounce
var y_restart_timer = 0.0  # Timer to re-enable y restart after bounce
const Y_RESTART_DISABLE_TIME = 0.5  # Half second disable duration

# Animation variables
var is_running_fast = false  # Flag to track if player is running fast

# Screenshake variables
var shake_intensity = 0.0
var shake_duration = 0.0
var original_camera_position = Vector2.ZERO

func _ready() -> void:
	%animation.play()
	
	# Initially hide stomp elements and jump animation, show normal elements
	if has_node("stomp_sprite"):
		$stomp_sprite.visible = false
	if has_node("stomp_collision"):
		$stomp_collision.disabled = true
	
	# Initially hide jump animation
	%jumpAnimation.visible = false
	
	# Initialize run particles (should start disabled)
	if has_node("runParticle"):
		$runParticle.emitting = false
	
	# Ensure normal collision is enabled initially
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = false
	
	# Store original camera position for screenshake
	if has_node("Camera2D"):
		original_camera_position = $Camera2D.position

func _physics_process(delta: float) -> void:
	# Update auto run timer
	update_auto_run_timer(delta)
	
	# Update screenshake
	update_screenshake(delta)
	
	# Update coyote time
	update_coyote_time(delta)
	
	# Update y restart timer
	update_y_restart_timer(delta)
	
	# Handle stomp input
	handle_stomp()
	
	# Handle jump input first
	handle_jump(delta)
	
	# Add the gravity (after jump handling)
	if not is_on_floor():
		var gravity_multiplier = 1.0
		
		# Make player fall faster when stomping
		if is_stomping:
			gravity_multiplier = FAST_FALL_MULTIPLIER
		
		velocity += get_gravity() * gravity_multiplier * delta

	# Update animation state
	update_animation_state()

	# Handle movement
	var direction := 0.0
	
	if auto_run:
		# Automatic running to the right for endless runner
		direction = 1.0
		
		# Allow player to slow down or speed up
		if Input.is_action_pressed("stomp"):
			direction = handle_stomp_input()
			update_animation_speed(false)  # Not running fast
		elif Input.is_action_pressed("speed_up"):
			direction = 1.5  # Speed boost
			update_animation_speed(true)   # Running fast
		else:
			update_animation_speed(false)  # Normal speed
	else:
		# Manual movement (original behavior)
		var stomp_input = -1.0 if Input.is_action_pressed("stomp") else 0.0
		var speed_input = 1.0 if Input.is_action_pressed("speed_up") else 0.0
		direction = stomp_input + speed_input
		update_animation_speed(Input.is_action_pressed("speed_up"))  # Running fast if speed_up pressed
	
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Handle run particles
	handle_run_particles()

	move_and_slide()

func handle_jump(delta: float) -> void:
	# Start jump with very small velocity (allow coyote time)
	if Input.is_action_just_pressed("jump") and can_jump() and not has_jumped:
		velocity.y = MIN_JUMP_VELOCITY  # Start with very small jump
		is_jumping = true
		has_jumped = true
		jump_time = 0.0
		coyote_timer = 0.0  # Reset coyote time when jumping
		add_screenshake(2.0, 0.1)  # Light shake on jump
		
		# Trigger jump particles
		if has_node("JumpParticle"):
			$JumpParticle.emitting = true
		
		# Play jump sound effect with pitch variety
		if has_node("jump_sfx"):
			$jump_sfx.pitch_scale = randf_range(0.9, 1.1)
			$jump_sfx.play()
		
		print("Jump started with velocity: ", velocity.y)
	
	# Track jump time while button is held
	if is_jumping and Input.is_action_pressed("jump"):
		jump_time += delta
		
		# Only start boosting after a small delay to ensure tap vs hold distinction
		if jump_time > JUMP_BOOST_DELAY and jump_time < MAX_JUMP_TIME:
			# Apply strong upward force while holding
			velocity.y += JUMP_BOOST_FORCE * delta
			# Cap at maximum jump velocity
			velocity.y = max(velocity.y, MAX_JUMP_VELOCITY)
			print("Boosting jump, velocity: ", velocity.y)
	
	# Stop boosting when button released or max time reached
	if is_jumping and (Input.is_action_just_released("jump") or jump_time >= MAX_JUMP_TIME):
		is_jumping = false
		print("Jump ended, final velocity: ", velocity.y)
	
	# Reset jump state when landing
	if is_on_floor():
		# Detect landing (was in air, now on ground)
		if not was_on_floor_last_frame:
			ScoreSystem.on_player_landed()
		
		has_jumped = false
		disable_y_restart = false  # Reset y restart disable when landing
		y_restart_timer = 0.0  # Reset timer when landing
		if not is_jumping:
			jump_time = 0.0
		# Stop stomping when landing
		if is_stomping:
			is_stomping = false
	
	# Update landing detection for next frame
	was_on_floor_last_frame = is_on_floor()

func update_coyote_time(delta: float) -> void:
	# Track if we were on floor last frame
	var currently_on_floor = is_on_floor()
	
	# If we just left the ground, start coyote timer
	if was_on_floor and not currently_on_floor:
		coyote_timer = COYOTE_TIME
	
	# Count down coyote time
	if coyote_timer > 0.0:
		coyote_timer -= delta
	
	# Update floor status for next frame
	was_on_floor = currently_on_floor

func update_y_restart_timer(delta: float) -> void:
	# Count down the y restart disable timer
	if y_restart_timer > 0.0:
		y_restart_timer -= delta
		
		# Re-enable y restart when timer expires
		if y_restart_timer <= 0.0:
			disable_y_restart = false
			print("Y restart re-enabled after timer")

func update_auto_run_timer(delta: float) -> void:
	# Count down the auto run timer
	if not auto_run and auto_run_timer < AUTO_RUN_DELAY:
		auto_run_timer += delta
		
		# Enable auto run when timer reaches delay
		if auto_run_timer >= AUTO_RUN_DELAY:
			auto_run = true
			print("Auto run enabled after ", AUTO_RUN_DELAY, " seconds")

func can_jump() -> bool:
	# Can jump if on floor OR within coyote time
	return is_on_floor() or coyote_timer > 0.0

func reset_jump_state():
	# Reset jump state for bouncing or other external forces
	is_jumping = false
	has_jumped = false
	jump_time = 0.0
	disable_y_restart = true  # Disable y restart after bounce
	y_restart_timer = Y_RESTART_DISABLE_TIME  # Start timer for re-enabling

func handle_stomp_input() -> float:
	# Handle stomp input logic with optional y restart and stomp slowdown
	
	# Restart the y velocity if going up for more snappy controls (unless disabled)
	if velocity.y < 0 and not disable_y_restart:
		velocity.y = 0
	
	# When in air, this becomes a stomp attack with slower horizontal movement
	return 0.3 if is_stomping else 0.5

func update_animation_speed(running_fast: bool):
	# Update animation speed based on running state
	if running_fast != is_running_fast:
		is_running_fast = running_fast
		
		if has_node("%animation"):
			var animation_player = %animation
			if is_running_fast:
				# Set to 10 FPS when running fast
				animation_player.speed_scale = 10.0 / 6.0  # Scale from 6 to 10 FPS
			else:
				# Set to 6 FPS when not running fast
				animation_player.speed_scale = 1.0  # Default speed (assuming 6 FPS is default)

func handle_stomp():
	# Check if player should be stomping
	var should_stomp = Input.is_action_pressed("stomp") and not is_on_floor() and auto_run and velocity.y > 0
	
	# Start stomping
	if should_stomp and not is_stomping:
		is_stomping = true
		print("Started stomping")
	
	# Stop stomping when landing or releasing stomp key
	elif is_stomping and (is_on_floor() or not Input.is_action_pressed("stomp")):
		is_stomping = false
		print("Stopped stomping")

func update_animation_state():
	# Determine which animation should be active based on player state
	var should_show_stomp = is_stomping
	var should_show_jump = not is_on_floor() and not is_stomping
	var should_show_running = is_on_floor() and not is_stomping
	
	# Update stomp animation
	%StompSprite.visible = should_show_stomp
	$StompCollisionShape.disabled = not should_show_stomp
	
	# Update jump animation
	%jumpAnimation.visible = should_show_jump
	if should_show_jump and not %jumpAnimation.is_playing():
		%jumpAnimation.play()
	
	# Update running animation
	%animation.visible = should_show_running
	if should_show_running and not %animation.is_playing():
		%animation.play()
	
	# Update collision shape - use stomp collision when stomping, regular otherwise
	$regularCollisionShape.disabled = should_show_stomp

func add_screenshake(intensity: float, duration: float):
	# Add screenshake effect
	shake_intensity = intensity
	shake_duration = duration

func update_screenshake(delta: float):
	# Update screenshake effect
	if shake_duration > 0.0:
		shake_duration -= delta
		
		if has_node("Camera2D"):
			var camera = $Camera2D
			# Generate random offset
			var shake_offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			camera.position = original_camera_position + shake_offset
		
		# Reduce intensity over time for smooth fade
		shake_intensity = lerp(shake_intensity, 0.0, delta * 5.0)
	else:
		# Reset camera to original position when shake ends
		if has_node("Camera2D"):
			$Camera2D.position = original_camera_position

func trigger_stomp_shake():
	# Trigger screenshake for enemy stomp
	add_screenshake(5.0, 0.2)  # Stronger shake for stomp

func handle_run_particles():
	# Handle run particles - emit while holding speed_up input (speed boost)
	var should_emit_run_particles = Input.is_action_pressed("speed_up")
	
	if has_node("runParticle"):
		var run_particle = $runParticle
		
		# Start emitting particles when conditions are met
		if should_emit_run_particles and not run_particle.emitting:
			run_particle.emitting = true
			print("Started run particles")
		
		# Stop emitting particles when conditions are no longer met
		elif not should_emit_run_particles and run_particle.emitting:
			run_particle.emitting = false
			print("Stopped run particles")
