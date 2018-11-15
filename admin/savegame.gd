extends Node

var doors = {}
var keys = {}
var crystals = {}
var key_total = 0
var player_type = ""

const save_file_name = "user://save.json"


func _ready():
	#debug line
	# save()
	
	
	restore()

func save ():
	var save_dict = {
		"doors" : doors,
		"keys": keys,
		"crystals": crystals,
		"key_total": key_total,
		"player_type": player_type
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
	key_total = save_dict.key_total
	player_type = save_dict.player_type
	
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
	keys[scene][key_name] = true
	
func get_key_count ():
	return key_total


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
	return acc