extends Area2D

export var key_name = ""

func _ready ():
	var scene = scene_transition.scene_to
	if savegame.is_key_taken(scene, key_name):
		queue_free()
	else:
		$anim.play("spin")

func _on_key_body_entered(body):
	var scene = scene_transition.scene_to
	if not savegame.is_key_taken(scene, key_name):
		$sound.play()
		$anim.play("get")
		savegame.take_key(scene, key_name)
