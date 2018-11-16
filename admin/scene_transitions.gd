extends Node

enum STATE {
	TRANSITIONING,
	NORMAL
}

var state

const player = preload("res://objects/player/player.tscn")
var current_player = null
var spawn_points = {}

# a string to the file path of the current scene
var scene_to
var spawn_to

func set_player(obj):
	player = obj
	
func set_respawn(scene, spawn_point_name):
	savegame.current_scene = scene
	savegame.current_spawn = spawn_point_name
	savegame.save()
	
func register_spawn_point(scene, spawn_point_name, spawn_point):
	
	if not spawn_points.has(scene):
		spawn_points[scene] = {}
	
	if not spawn_points[scene].has(spawn_point_name):
		spawn_points[scene][spawn_point_name] = spawn_point
	
func respawn():
	transition_to(savegame.current_scene, savegame.current_spawn)
	
func spawn():
	spawn_at(savegame.current_scene, savegame.current_spawn)
	
func transition_to (scene, spawn_point):
	if TRANSITIONING == state:
		return
	state = TRANSITIONING
	scene_to = scene
	spawn_to = spawn_point
	# the player animation doesn't pause
	get_tree().paused = true
	current_player.get_node("transition").play("out")
	$out_timer.start()
	
func spawn_at(scene, spawn_point_name):
	scene_to = scene
	spawn_to = spawn_point_name
	get_tree().change_scene(scene_to)
	# unpause here, to update background and reduce graphical glitches
	call_deferred("_spawn_player")
	get_tree().paused = false
	
	
	$in_timer.start()

func _spawn_player ():
	if current_player != null:
		current_player.queue_free()
	current_player = player.instance()
	current_player.position = spawn_points[scene_to][spawn_to]
	get_node("/root").add_child(current_player)
	

func _on_out_timer_timeout():
	if NORMAL == state:
		return
	spawn_at (scene_to, spawn_to)

func _on_in_timer_timeout():
	state = NORMAL
	
	