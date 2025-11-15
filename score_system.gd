extends Node

# Score System for Retro Runner
# Tracks player progress and awards points for distance traveled

# Signals for UI updates
signal score_changed(new_score: int)
signal distance_changed(new_distance: float)
signal highscore_changed(new_highscore: int)
signal combo_changed(combo_count: int, combo_points: int)

# Score settings
const POINTS_PER_DISTANCE_UNIT: int = 10  # Points awarded per distance unit traveled
const DISTANCE_UNIT: float = 100.0  # How many pixels = 1 distance unit for scoring
const SAVE_FILE_PATH: String = "user://highscore.save"
const DUCK_JUMP_BASE_POINTS: int = 50  # Base points for each duck jump

# Score tracking variables
var current_score: int = 0
var distance_score: int = 0  # Points from distance traveled
var combo_score: int = 0  # Points from completed combos
var highscore: int = 0
var total_distance_traveled: float = 0.0
var last_recorded_x_position: float = 0.0
var highest_x_position: float = 0.0

# Combo tracking variables
var combo_count: int = 0  # Number of consecutive duck jumps
var combo_total_points: int = 0  # Total points accumulated in current combo
var is_in_air: bool = false  # Track if player is airborne

# Reference to player (will be set by game scene)
var player: CharacterBody2D = null

func _ready() -> void:
	load_highscore()
	print("Score System initialized - High Score: ", highscore)

func _process(delta: float) -> void:
	if player != null:
		update_distance_and_score()

# Call this from the game scene to set player reference
func set_player(player_node: CharacterBody2D) -> void:
	player = player_node
	if player:
		# Initialize starting position
		last_recorded_x_position = player.global_position.x
		highest_x_position = player.global_position.x
		print("Player reference set in score system")

# Update distance traveled and award points
func update_distance_and_score() -> void:
	if not player:
		return
	
	var current_x = player.global_position.x
	
	# Only count forward progress (no negative points for going backwards)
	if current_x > highest_x_position:
		var distance_gained = current_x - highest_x_position
		total_distance_traveled += distance_gained
		highest_x_position = current_x
		
		# Calculate new distance score
		var new_distance_score = int(total_distance_traveled / DISTANCE_UNIT) * POINTS_PER_DISTANCE_UNIT
		
		# Update distance score if it changed
		if new_distance_score != distance_score:
			distance_score = new_distance_score
			# Update total score (distance + combo points)
			current_score = distance_score + combo_score
			score_changed.emit(current_score)
			
			# Check for new high score
			if current_score > highscore:
				highscore = current_score
				save_highscore()
				highscore_changed.emit(highscore)
				print("NEW HIGH SCORE: ", highscore)
		
		# Emit distance update
		distance_changed.emit(total_distance_traveled)

# Get current score
func get_score() -> int:
	return current_score

# Get high score
func get_highscore() -> int:
	return highscore

# Get distance traveled in units
func get_distance_units() -> int:
	return int(total_distance_traveled / DISTANCE_UNIT)

# Get raw distance traveled
func get_distance_traveled() -> float:
	return total_distance_traveled

# Reset score and distance (for new game)
func reset_score() -> void:
	current_score = 0
	distance_score = 0
	combo_score = 0
	total_distance_traveled = 0.0
	last_recorded_x_position = 0.0
	highest_x_position = 0.0
	
	# Reset combo variables
	combo_count = 0
	combo_total_points = 0
	is_in_air = false
	
	if player:
		last_recorded_x_position = player.global_position.x
		highest_x_position = player.global_position.x
	
	score_changed.emit(current_score)
	distance_changed.emit(total_distance_traveled)
	combo_changed.emit(combo_count, combo_total_points)
	print("Score system reset")

# Add bonus points (for future features like pickups)
func add_bonus_points(points: int) -> void:
	combo_score += points
	# Update total score (distance + combo points)
	current_score = distance_score + combo_score
	score_changed.emit(current_score)
	
	# Check for new high score
	if current_score > highscore:
		highscore = current_score
		save_highscore()
		highscore_changed.emit(highscore)
		print("NEW HIGH SCORE: ", highscore)
	
	print("Bonus points added: ", points, " | Total score: ", current_score)

# Add collectible points (disketa, DVD, ploca, etc.)
func add_collectible_points(points: int) -> void:
	combo_score += points
	# Update total score (distance + combo points)
	current_score = distance_score + combo_score
	score_changed.emit(current_score)
	
	# Check for new high score
	if current_score > highscore:
		highscore = current_score
		save_highscore()
		highscore_changed.emit(highscore)
		print("NEW HIGH SCORE: ", highscore)
	
	print("Collectible points added: ", points, " | Total score: ", current_score)

# Combo System Functions
func on_duck_jump() -> void:
	# Increment combo count
	combo_count += 1
	
	# Calculate points for this jump (base points * combo multiplier)
	var jump_points = DUCK_JUMP_BASE_POINTS * combo_count
	combo_total_points += jump_points
	
	# Mark player as in air
	is_in_air = true
	
	# Emit combo update
	combo_changed.emit(combo_count, combo_total_points)
	
	print("Duck jump! Combo: ", combo_count, " | Jump points: ", jump_points, " | Total combo: ", combo_total_points)

func on_player_landed() -> void:
	# Only process if we have a combo and were in air
	if combo_count > 0 and is_in_air:
		# Add combo points to permanent combo score
		combo_score += combo_total_points
		# Update total score (distance + combo points)
		current_score = distance_score + combo_score
		score_changed.emit(current_score)
		
		# Check for new high score
		if current_score > highscore:
			highscore = current_score
			save_highscore()
			highscore_changed.emit(highscore)
			print("NEW HIGH SCORE: ", highscore)
		
		print("Combo completed! Added ", combo_total_points, " points to score. New score: ", current_score)
		
		# Reset combo
		combo_count = 0
		combo_total_points = 0
		combo_changed.emit(combo_count, combo_total_points)
	
	is_in_air = false

# Get current combo info
func get_combo_count() -> int:
	return combo_count

func get_combo_points() -> int:
	return combo_total_points

# Save high score to file
func save_highscore() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(highscore)
		file.close()
		print("High score saved: ", highscore)
	else:
		print("Failed to save high score")

# Load high score from file
func load_highscore() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			highscore = file.get_32()
			file.close()
			print("High score loaded: ", highscore)
		else:
			print("Failed to load high score")
	else:
		highscore = 0
		print("No high score file found, starting with 0")

# Debug function to print current stats
func print_stats() -> void:
	print("=== Score System Stats ===")
	print("Score: ", current_score)
	print("High Score: ", highscore)
	print("Distance traveled: ", total_distance_traveled)
	print("Distance units: ", get_distance_units())
	print("Player X position: ", player.global_position.x if player else "No player")
