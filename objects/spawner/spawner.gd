extends Position2D

export (String, FILE) var object_path = ""
export var respawn_delay = 1

var obj

const bullet = preload("res://objects/bullet/bullet.tscn")

func _ready():
	obj = load(object_path)
	$respawn_timer.wait_time = respawn_delay
	call_deferred("spawn")

func spawn():
	var new_obj = obj.instance()
	new_obj.position = position
	get_parent().add_child(new_obj)
	$anim.play("poof")
	new_obj.connect("tree_exiting", self, "respawn")
	
func respawn():
	$respawn_timer.start()

func _on_respawn_timer_timeout():
	spawn()
