extends Area2D

export var spawn_name = ""
var scene = scene_transition.scene_to

var active = true

func _ready():
	scene_transition.register_spawn_point(scene, spawn_name, position)
	if savegame.current_scene == scene and savegame.current_spawn == spawn_name:
		$anim.play("active")
	else:
		deactivate()
		
func _activate ():
	if active == true:
		return
	active = true
	$sound.play()
	$anim.play("active")
	
func deactivate ():
	$anim.play("inactive")
	active = false

func _on_checkpoint_body_entered(body):
	body.enter_checkpoint(self)
	scene_transition.set_respawn(scene, spawn_name)
	_activate()
