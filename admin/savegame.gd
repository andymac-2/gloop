extends Node

var doors = {}
var keys = {}
var crystals = {}
var green_gems = {}
var player_type = ""
var key_total = 0

# String: spawn point name to spawn at
var current_spawn = ""
# A String: the path to the scene to respawn at, may not be the current scene
# beginning: res://stages/overworld/castle_entrance.tscn
var current_scene  = "res://stages/overworld/castle_entrance.tscn"
const save_file_name = "user://save.json"

# not actually part of savegame.
var green_gem_total = 0
var crystal_total = 0

func new_game():
	save()
	start_game()
	
func start_game():
	restore()
	scene_transition.spawn()
	
func file_exists():
	var file = File.new()
	return file.file_exists(save_file_name)


func _ready():
	#debug line to restart fresh
	# save()
	
	
	restore()
	scene_transition.spawn()

func save ():
	var save_dict = {
		"doors" : doors,
		"keys": keys,
		"crystals": crystals,
		"key_total": key_total,
		"player_type": player_type,
		"current_spawn": current_spawn,
		"current_scene": current_scene,
		"green_gems": green_gems
	}
	
	var file = File.new()
	file.open(save_file_name, File.WRITE)
	file.store_string(to_json(save_dict))
	file.close()
	

func restore():
	var file = File.new()
	if not file.file_exists(save_file_name):
		save()
	
	file.open(save_file_name, file.READ)
	
	var save_dict = parse_json(file.get_as_text())
	file.close()
	
	doors = save_dict.doors
	keys = save_dict.keys
	crystals = save_dict.crystals
	player_type = save_dict.player_type
	current_spawn = save_dict.current_spawn
	current_scene = save_dict.current_scene
	green_gems = save_dict.green_gems
	key_total = save_dict.key_total
	
	get_total_green_gems()
	get_total_crystals()
	
	hud.update_hud()
	
#door fuctions
# door[scene][door_name] == true iff door is unlocked
func _check_door (scene, door_name):
	if not doors.has(scene):
		doors[scene] = {}
	if not doors[scene].has(door_name):
		doors[scene][door_name] = false
		
func register_door (scene, door_name, is_unlocked):
	if not doors.has(scene):
		doors[scene] = {}
	if not doors[scene].has(door_name):
		doors[scene][door_name] = is_unlocked
		
func is_door_unlocked (scene, door_name):
	_check_door(scene, door_name)
	return doors[scene][door_name]
	
func unlock_door (scene, door_name):
	_check_door (scene, door_name)
	doors[scene][door_name] = true

# key functions
# key[scene][key_name] == true iff key has been taken
func _check_key (scene, key_name):
	if not keys.has(scene):
		keys[scene] = {}
	if not keys[scene].has(key_name):
		keys[scene][key_name] = false
	
func is_key_taken (scene, key_name):
	_check_key (scene, key_name)
	return keys[scene][key_name]
	
func take_key (scene, key_name):
	_check_key (scene, key_name)
	if keys[scene][key_name] == false:
		key_total += 1
	hud.update_hud()
	keys[scene][key_name] = true
	
func get_total_keys ():
	return key_total
	
func use_key ():
	key_total -= 1
	hud.update_hud()


#crystal functions
# crystal[scene][Crystal_name] == true iff crystal has been taken
func _check_crystal (scene, crystal_name):
	if not crystals.has(scene):
		crystals[scene] = {}
	if not crystals[scene].has(crystal_name):
		crystals[scene][crystal_name] = false

func is_crystal_taken (scene, crystal_name):
	_check_crystal (scene, crystal_name)
	return crystals[scene][crystal_name]
	
func take_crystal (scene, crystal_name):
	_check_crystal (scene, crystal_name)
	if crystals[scene][crystal_name] == false:
		crystal_total += 1
	hud.update_hud()
	crystals[scene][crystal_name] = true
	
func get_crystal_count (scene):
	if not crystals.has(scene):
		return 0
		
	var acc = 0
	for crystal in crystals[scene]:
		if crystals[scene][crystal] == true:
			acc += 1
	return acc
	
func get_total_crystals ():
	var acc = 0
	for scene in crystals:
		acc += get_crystal_count(scene)
	crystal_total = acc
	return acc
	
#green gem functions
# crystal[scene][Crystal_name] == true iff crystal has been taken
func _check_green_gem (scene, green_gem_name):
	if not green_gems.has(scene):
		green_gems[scene] = {}
	if not green_gems[scene].has(green_gem_name):
		green_gems[scene][green_gem_name] = false

func is_green_gem_taken (scene, green_gem_name):
	_check_green_gem (scene, green_gem_name)
	return green_gems[scene][green_gem_name]
	
func take_green_gem (scene, green_gem_name):
	_check_green_gem (scene, green_gem_name)
	if green_gems[scene][green_gem_name] == false:
		green_gem_total += 1
	hud.update_hud()
	green_gems[scene][green_gem_name] = true
	
func _get_green_gem_count (scene):
	if not green_gems.has(scene):
		return 0
		
	var acc = 0
	for green_gem in green_gems[scene]:
		if green_gems[scene][green_gem] == true:
			acc += 1
	return acc
	
func get_total_green_gems ():
	var acc = 0
	for scene in green_gems:
		acc += _get_green_gem_count(scene)
	green_gem_total = acc
	return acc