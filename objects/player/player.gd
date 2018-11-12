extends RigidBody2D

enum STATE {
	ALIVE,
	DEAD,
	INVINCIBLE
}
var state = ALIVE


var anim = ""
# true if character is jumping in the air, or has landed without releasing the
# jump key
var type = ""
var jumping = false
var actioning = false
var on_ground = false
var floor_h_velocity = 0.0
var action_cool_down = 0.0

# Player buttons
var jump = false
var move_left = false
var move_right = false
var crouch = false
var action = false

const WALK_ACCEL = 600.0
const WALK_DECEL = 1600.0
const MAX_VELOCITY = 300.0
const AIR_ACCEL = 800.0
const AIR_DECEL = 800.0
const JUMP_VELOCITY = 460.0
const STOP_JUMP_FORCE = 1500.0
const FALL_FORCE = 450.0

# time in seconds
const MAGE_SHOOT_COOLDOWN = 0.3

# set to the object that we can enter
var over_enterable_object = false
var enter_object

var last_checkpoint = null

const bullet = preload("res://objects/bullet/bullet.tscn")

# DAMAGE
func burn ():
	damage ()
		
func damage ():
	if INVINCIBLE == state or DEAD == state:
		return
	if type != "":
		_set_type("")
		state = INVINCIBLE
		$poof.play("poof")
		$invincibility_timer.start()
		$flash_timer.start()
	else:
		_die ()
		
func _on_flash_timer_timeout():
	visible = not visible

func _on_invincibility_timer_timeout():
	$flash_timer.stop()
	visible = true
	state = ALIVE

func _ready ():
	$transition.play("in")
	type = savegame.player_type


# Powerup functions
func _absorb (ground):
	var oldtype = type
	if ground.has_method("absorb"):
		var t = ground.absorb()
		_set_type(t)
	else:
		actioning = false
		_set_type("")
		
	if (type != oldtype):
		$poof.play("poof")
		
func _set_type (t):
	type = t
	savegame.player_type = type
		
func enter_checkpoint(cp):
	if DEAD == state:
		return
	if last_checkpoint != null:
		last_checkpoint.deactivate()
	last_checkpoint = cp
	
func _die ():
	if DEAD == state:
		return
	state = DEAD
	scene_transition.respawn()

#decelerates linear velocity by decel, mutates lv
func _decelerate (lv, step, decel):
	var xv = abs(lv.x)
	xv -= decel * step
	if xv < 0:
		xv = 0
	lv.x = sign(lv.x) * xv
	return lv

# applies the player movement, mutates lv
func _apply_player_movement (lv, step, accel, decel, max_vel):
	if move_right == move_left and on_ground:
		lv = _decelerate (lv, step, decel)
	elif move_left:
		if lv.x > 0:
			lv.x -= decel * step
		elif lv.x > -max_vel:
			lv.x -= accel * step
	elif move_right:
		if lv.x < 0:
			lv.x += decel * step
		elif lv.x < max_vel:
			lv.x += accel * step
	return lv

# player movement/acceleration when in "normal" state
# lv is linear velocity
func _normal_player_movement (lv, step):
	if on_ground and crouch:
		return _decelerate (lv, step, WALK_DECEL)
	elif on_ground:
		return _apply_player_movement (lv, step, WALK_ACCEL, WALK_DECEL, MAX_VELOCITY)
	else:
		return _apply_player_movement (lv, step, AIR_ACCEL, AIR_DECEL, MAX_VELOCITY)
		
func _apply_gravity(lv, step, s):
	if not on_ground:
		if not jump and lv.y < 0:
			lv.y += STOP_JUMP_FORCE * step
		elif not jump and lv.y > 0:
			lv.y += FALL_FORCE * step
	return lv + s.get_total_gravity() * step

func _enter_object ():
	if not over_enterable_object:
		return 
	enter_object.enter()
	
func _find_ground (bodyState):
	for x in range(bodyState.get_contact_count()):
		var ci = bodyState.get_contact_local_normal(x)
		if ci.dot(Vector2(0, -1)) > 0.6:
			on_ground = true
			return x
	on_ground = false
	return -1
	
func _is_facing_right ():
	return 1 == sign($sprite.scale.x)
	
func _set_animation (lv):
	var new_anim
	if on_ground and crouch:
		new_anim = "crouch_" + type
	elif actioning and action:
		new_anim = "action_" + type
	elif on_ground:
		if abs(lv.x) < 0.1:
			new_anim = "idle_" + type
		elif lv.x < 0 and not move_left:
			new_anim = "sliding_" + type
		elif lv.x > 0 and not move_right:
			new_anim = "sliding_" + type
		else:
			new_anim = "run_" + type
	else:
		if lv.y < 0:
			new_anim = "jumping_" + type
		else:
			new_anim = "falling_" + type
			
	if sign(lv.x) != 0 and sign(lv.x) != sign($sprite.scale.x):
		$sprite.scale.x = -$sprite.scale.x
			
	if new_anim != anim:
		anim = new_anim
		$anim.play(anim)
		
func _decompensate_ground_inertia (lv):
	lv.x -= floor_h_velocity
	floor_h_velocity = 0.0
	return lv
	
func _jump (lv):
	if not jumping and jump:
		lv.y = -JUMP_VELOCITY - abs(lv.x) * 0.2
		jumping = true
		$sound_jump.play()
	return lv


func _compensate_ground_inertia (lv, bodyState, floor_index):
	if on_ground:
		floor_h_velocity = bodyState.get_contact_collider_velocity_at_position(floor_index).x
		lv.x += floor_h_velocity
	return lv
	

func _mage_action(step):
	# A good idea when implementing characters of all kinds,
	# compensates for physics imprecision, as well as human reaction delay.
	if action_cool_down <= 0 and not action:
		actioning = false
		
	if action and not actioning:
		actioning = true
		action_cool_down = MAGE_SHOOT_COOLDOWN
		
		var bi = bullet.instance()
		var ss
		if _is_facing_right():
			ss = 1.0
		else:
			ss = -1.0
		var pos = position + $bullet_shoot.position * Vector2(ss, 1.0)
		
		bi.position = pos
		get_parent().add_child(bi)
		
		var FIREBALL_VELOCITY = 300.0
		bi.linear_velocity = Vector2(FIREBALL_VELOCITY * ss, -20)
		
		$sound_shoot.play()
		
		bi.set_collision_mask_bit(0, true)
		bi.set_collision_mask_bit(6, true)
	else:
		action_cool_down -= step
	

# called during physics simulation. 
func _integrate_forces(s):
	if DEAD == state:
		state = ALIVE
		return
	
	var lv = s.get_linear_velocity()
	var step = s.get_step()
	var ground
	
	# Get the controls
	move_left = Input.is_action_pressed("move_left")
	move_right = Input.is_action_pressed("move_right")
	jump = Input.is_action_pressed("jump")
	crouch = Input.is_action_pressed("crouch")
	action = Input.is_action_pressed("action")
	var enter = Input.is_action_pressed("enter")
	
	var floor_index = _find_ground(s)
	if floor_index >= 0:
		ground = s.get_contact_collider_object(floor_index)
	
	lv = _decompensate_ground_inertia(lv)

	match type:
		"mage":
			lv = _normal_player_movement (lv, step)
			_set_animation(lv)
			_mage_action(step)
		"tank":
			lv = _normal_player_movement (lv, step)
			_set_animation(lv)
		"":
			lv = _normal_player_movement (lv, step)
			_set_animation(lv)

	lv = _compensate_ground_inertia(lv, s, floor_index)

	if on_ground and crouch:
		_absorb(ground)
	elif on_ground: # and not crouching
		if not jump:
			jumping = false
			
		lv = _jump(lv)
			
	lv = _apply_gravity(lv, step, s)
	s.set_linear_velocity(lv)
	
	if enter && on_ground:
		_enter_object()
