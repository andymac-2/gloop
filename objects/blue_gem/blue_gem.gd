extends Area2D

# Member variables
export var crystal_name = ""

func _ready ():
	var scene = scene_transition.scene_to
	if savegame.is_crystal_taken(scene, crystal_name):
		queue_free()
	else:
		$anim.play("rotate")

func _on_blue_gem_body_entered(body):
	var scene = scene_transition.scene_to
	if not savegame.is_crystal_taken(scene, crystal_name):
		$anim.play("get")
		savegame.take_crystal(scene, crystal_name)
