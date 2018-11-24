extends RigidBody2D

enum STATE {
	ALIVE,
	REELING
	DYING
}

export var green_gem_name = ""
export (String) var door_name = ""
export (String, FILE) var dest_scene = ""
export var dest_spawn = ""

var direction = 1
var anim = "rolling"
var state = ALIVE
var hp = 3

const WALK_SPEED = 30
const green_gem = preload("res://objects/green_gem/green_gem.tscn")
const door = preload("res://objects/door/door.tscn")

var rc_left
var rc_right

func _ready():
	var scene = scene_transition.scene_to
	if savegame.is_green_gem_taken(scene, green_gem_name):
		call_deferred("_dissapear")
		return
	
	$anim.play("rolling")
	rc_left = $raycast_left
	rc_right = $raycast_right

func _pre_die():
	if DYING == state:
		return
		
	state = DYING
	
	_dissapear()
	
	var new_gem = green_gem.instance()
	new_gem.crystal_name = green_gem_name

	var pos = position
	pos.y -= 20
	new_gem.position = pos
	get_parent().add_child(new_gem)
	
func _dissapear():
	state = DYING
	
	$anim.play("poof")
	$shape.queue_free()
	$shape2.queue_free()
	
	var new_door = door.instance()
	var pos = position
	pos.y += $shape.position.y + $shape.shape.radius * $shape.scale.y
	print (pos.y)
	new_door.position = pos
	new_door.state = 1
	new_door.door_name = door_name
	new_door.dest_scene = dest_scene
	new_door.dest_spawn = dest_spawn
	get_parent().add_child(new_door)
	
	
func crush ():
	if hp > 0:
		hp -= 1
		state = REELING
		$invincibility.start()
		$flash_timer.start()
		return
		
	_pre_die()

func _integrate_forces(s):
	if state == DYING:
		s.set_linear_velocity(Vector2(0,0))
		return
	
	var lv = s.get_linear_velocity()

	var wall_side = 0.0
	
	for i in range(s.get_contact_count()):
		var cc = s.get_contact_collider_object(i)
		var dp = s.get_contact_local_normal(i)

		var obj = s.get_contact_collider_object(i)
		if obj.has_method("bounce"):
			obj.bounce(Vector2(sign(dp.x) * 4, 80))
		
		if dp.x > 0.8:
			wall_side = 1.0
		elif dp.x < -0.8:
			wall_side = -1.0
	
	if state == REELING:
		return
			
	if wall_side != 0 and wall_side != direction:
		direction = -direction
		$sprite.scale.x = -$sprite.scale.x
	if direction < 0 and not rc_left.is_colliding() and rc_right.is_colliding():
		direction = -direction
		$sprite.scale.x = -$sprite.scale.x
	elif direction > 0 and not rc_right.is_colliding() and rc_left.is_colliding():
		direction = -direction
		$sprite.scale.x = -$sprite.scale.x
		
	lv.x = direction * WALK_SPEED
	
	s.set_linear_velocity(lv)


func _on_invincibility_timeout():
	$flash_timer.stop()
	state = ALIVE
	visible = true
	
func _on_flash_timer_timeout():
	visible = not visible
