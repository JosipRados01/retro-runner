extends ParallaxBackground

# Background variation options
enum SkyType { BLUE, ORANGE }
enum BackType { BUILDINGS, PLANINE }
enum MidType { BUILDINGS, PLANINE }

# Export variables to set in editor or via code
@export var sky_type: SkyType = SkyType.ORANGE
@export var back_type: BackType = BackType.PLANINE
@export var mid_type: MidType = MidType.PLANINE

func _ready():
	setup_background()
	randomize_background()

func setup_background():
	# Configure sky layer
	setup_sky_layer()
	# Configure back layer
	setup_back_layer()
	# Configure mid layer
	setup_mid_layer()

func setup_sky_layer():
	var sky_layer = $sky
	
	match sky_type:
		SkyType.BLUE:
			# Show blue sky, hide orange
			if sky_layer.has_node("BlueSky"):
				sky_layer.get_node("BlueSky").visible = true
			if sky_layer.has_node("BlueSky2"):
				sky_layer.get_node("BlueSky2").visible = true
			if sky_layer.has_node("orangeSky"):
				sky_layer.get_node("orangeSky").visible = false
			if sky_layer.has_node("orangeSky2"):
				sky_layer.get_node("orangeSky2").visible = false
			print("Sky set to: BLUE")
		SkyType.ORANGE:
			# Show orange sky, hide blue
			if sky_layer.has_node("BlueSky"):
				sky_layer.get_node("BlueSky").visible = false
			if sky_layer.has_node("BlueSky2"):
				sky_layer.get_node("BlueSky2").visible = false
			if sky_layer.has_node("orangeSky"):
				sky_layer.get_node("orangeSky").visible = true
			if sky_layer.has_node("orangeSky2"):
				sky_layer.get_node("orangeSky2").visible = true
			print("Sky set to: ORANGE")

func setup_back_layer():
	var back_layer = $Backlayer
	
	match back_type:
		BackType.BUILDINGS:
			# Show buildings, hide planine
			if back_layer.has_node("BackBuildings"):
				back_layer.get_node("BackBuildings").visible = true
			if back_layer.has_node("BackBuildings2"):
				back_layer.get_node("BackBuildings2").visible = true
			if back_layer.has_node("BackPlanine"):
				back_layer.get_node("BackPlanine").visible = false
			if back_layer.has_node("BackPlanine2"):
				back_layer.get_node("BackPlanine2").visible = false
			print("Back layer set to: BUILDINGS")
		BackType.PLANINE:
			# Show planine, hide buildings
			if back_layer.has_node("BackBuildings"):
				back_layer.get_node("BackBuildings").visible = false
			if back_layer.has_node("BackBuildings2"):
				back_layer.get_node("BackBuildings2").visible = false
			if back_layer.has_node("BackPlanine"):
				back_layer.get_node("BackPlanine").visible = true
			if back_layer.has_node("BackPlanine2"):
				back_layer.get_node("BackPlanine2").visible = true
			print("Back layer set to: PLANINE")

func setup_mid_layer():
	var mid_layer = $MidLayer
	
	match mid_type:
		MidType.BUILDINGS:
			# Show buildings, hide planine
			if mid_layer.has_node("MidBuildings"):
				mid_layer.get_node("MidBuildings").visible = true
			if mid_layer.has_node("MidBuildings2"):
				mid_layer.get_node("MidBuildings2").visible = true
			if mid_layer.has_node("midPlanine"):
				mid_layer.get_node("midPlanine").visible = false
			if mid_layer.has_node("Midplanine2"):
				mid_layer.get_node("Midplanine2").visible = false
			print("Mid layer set to: BUILDINGS")
		MidType.PLANINE:
			# Show planine, hide buildings
			if mid_layer.has_node("MidBuildings"):
				mid_layer.get_node("MidBuildings").visible = false
			if mid_layer.has_node("MidBuildings2"):
				mid_layer.get_node("MidBuildings2").visible = false
			if mid_layer.has_node("midPlanine"):
				mid_layer.get_node("midPlanine").visible = true
			if mid_layer.has_node("Midplanine2"):
				mid_layer.get_node("Midplanine2").visible = true
			print("Mid layer set to: PLANINE")

# Public functions to change background dynamically
func set_sky_type(new_sky_type: SkyType):
	sky_type = new_sky_type
	setup_sky_layer()

func set_back_type(new_back_type: BackType):
	back_type = new_back_type
	setup_back_layer()

func set_mid_type(new_mid_type: MidType):
	mid_type = new_mid_type
	setup_mid_layer()

# Convenience function to set all at once
func set_background_variant(new_sky: SkyType, new_back: BackType, new_mid: MidType):
	sky_type = new_sky
	back_type = new_back
	mid_type = new_mid
	setup_background()

# Random background variant
func randomize_background():
	sky_type = SkyType.values()[randi() % SkyType.size()]
	back_type = BackType.values()[randi() % BackType.size()]
	mid_type = MidType.values()[randi() % MidType.size()]
	setup_background()
	print("Randomized background variant")
