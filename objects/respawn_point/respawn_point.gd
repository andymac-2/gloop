extends Position2D

export var spawn_name = ""
var scene = scene_transition.scene_to

func _ready():
	scene_transition.register_spawn_point(scene, spawn_name, position)
	scene_transition.set_respawn(scene, spawn_name)
