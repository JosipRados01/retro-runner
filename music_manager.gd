extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var static_player: AudioStreamPlayer
var music_stream = preload("res://sfx/arcade-beat-323176.mp3")
var death_sound_stream = preload("res://sfx/duck_bounce.wav")
var pickup_sound_stream = preload("res://sfx/jump.wav")
var static_sound_stream = preload("res://sfx/radio-static-323621.mp3")  # Using jump sound as placeholder for static

func _ready():
	# Create an AudioStreamPlayer for persistent music
	music_player = AudioStreamPlayer.new()
	music_player.stream = music_stream
	music_player.volume_db = -10.0
	add_child(music_player)
	
	# Create an AudioStreamPlayer for sound effects
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -5.0
	add_child(sfx_player)
	
	# Create an AudioStreamPlayer for radio static
	static_player = AudioStreamPlayer.new()
	static_player.volume_db = -8.0
	add_child(static_player)
	
	# Connect to finished signal for looping
	music_player.finished.connect(_on_music_finished)
	static_player.finished.connect(_on_static_finished)

func start_music():
	# Stop static when music starts
	stop_static()
	
	if music_player and not music_player.playing:
		music_player.play()
		print("Music started")

func stop_music():
	if music_player and music_player.playing:
		music_player.stop()
		print("Music stopped")

func play_death_sound():
	if sfx_player:
		sfx_player.stream = death_sound_stream
		sfx_player.pitch_scale = 0.6
		sfx_player.play()
		print("Death sound played")

func play_pickup_sound():
	if sfx_player:
		sfx_player.stream = pickup_sound_stream
		sfx_player.pitch_scale = randf_range(1.2, 1.8)  # Higher pitch for pickup sound
		sfx_player.volume_db = -5.0  # Lower volume for pickup sound
		sfx_player.play()
		print("Pickup sound played")

func play_static():
	if static_player and not static_player.playing:
		static_player.stream = static_sound_stream
		static_player.play()
		print("Radio static started")

func stop_static():
	if static_player and static_player.playing:
		static_player.stop()
		print("Radio static stopped")

func _on_music_finished():
	# Restart the music when it finishes to create a loop
	if music_player:
		music_player.play()

func _on_static_finished():
	# Loop the static sound
	if static_player and static_player.stream:
		static_player.play()
