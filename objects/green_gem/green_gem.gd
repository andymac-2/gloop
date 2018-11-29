extends Area2D

# Member variables
export var crystal_name = ""

func _ready ():
	var scene = scene_transition.scene_to
	if savegame.is_green_gem_taken(scene, crystal_name):
		queue_free()
	else:
		$anim.play("rotate")

func _on_green_gem_body_entered(body):
	var scene = scene_transition.scene_to
	if not savegame.is_green_gem_taken(scene, crystal_name):
		$sound.play()
		$anim.play("get")
		savegame.take_green_gem(scene, crystal_name)
