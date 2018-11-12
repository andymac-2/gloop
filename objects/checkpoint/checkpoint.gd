extends Area2D

export var spawn_name = ""
var scene = scene_transition.scene_to

func _ready():
	scene_transition.register_spawn_point(scene, spawn_name, position)
	
func deactivate ():
	$anim.play("inactive")

func _on_checkpoint_body_entered(body):
	body.enter_checkpoint(self)
	scene_transition.set_respawn(scene, spawn_name)
	$anim.play("active")
