extends TileMapLayer

# Collectible scenes to spawn
var collectible_scenes: Array[PackedScene] = [
	preload("res://disketa.tscn"),
	preload("res://dvd.tscn"),
	preload("res://ploca_r.tscn")
]

# Spawn chance (0.0 to 1.0) - probability of spawning a collectible
@export var spawn_chance: float = 0.7

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Check if we should spawn a collectible based on spawn chance
	if randf() <= spawn_chance:
		spawn_random_collectible()

func spawn_random_collectible():
	var point = $point_spawn
	if not point:
		print("Warning: point_spawn marker not found!")
		return
	
	# Select a random collectible scene
	var random_index = randi() % collectible_scenes.size()
	var selected_scene = collectible_scenes[random_index]
	
	# Load and instantiate the selected scene
	var collectible_instance = selected_scene.instantiate()
	
	# Position it at the spawn point
	collectible_instance.global_position = point.global_position
	
	# Add to the parent scene (usually the game scene)
	get_parent().add_child(collectible_instance)
	
	print("Spawned collectible: ", selected_scene.resource_path, " at position: ", point.global_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
