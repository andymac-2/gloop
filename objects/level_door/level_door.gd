extends Area2D

enum STATE {
	LOCKED = 0,
	UNLOCKED = 1,
	UNLOCKING = 2,
}
export (String) var door_name = ""
export (String, FILE) var dest_scene = ""
export var dest_spawn = ""
export var total_crystals = 30
export (STATE) var state = UNLOCKED

var player_present = false
var scene = scene_transition.scene_to

const POSITION_OFFSET = Vector2 (0, -10)

func _ready():
	scene_transition.register_spawn_point (
		scene, door_name, position + POSITION_OFFSET)
		
	savegame.register_door (scene, door_name, state == UNLOCKED)
	if savegame.is_door_unlocked (scene, door_name):
		state = UNLOCKED
		$locked_door.visible = false
	else:
		state = LOCKED
		$locked_door.visible = true
		
	var crystals = savegame.get_crystal_count(dest_scene)
	$label.text = String(crystals) + "/" + String(total_crystals)
	
		
func enter():
	if player_present == false:
		return
	if LOCKED == state and savegame.key_total > 0:
		savegame.key_total -= 1
		savegame.unlock_door(scene, door_name)
		# transition occurs as part of animation
		state = UNLOCKING
		#poof anim will call _unlock
		$sound_unlock.play()
		$poof.play("unlock")
	#TODO: if locked play sound or visual cue that door is locked.
	if UNLOCKED == state:
		$sound_open.play()
		_transition ()

func _unlock():
	state = UNLOCKED
		
func _transition():
	scene_transition.transition_to(dest_scene, dest_spawn)

func _on_level_door_body_entered(body):
	player_present = true
	body.enter_object = self
	body.over_enterable_object = true

func _on_level_door_body_exited(body):
	body.over_enterable_object = true
	player_present = false
