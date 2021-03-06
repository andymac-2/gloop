extends RigidBody2D

enum STATE {
	ALIVE,
	DEAD,
	DYING,
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
var bounce_normal = null

# this is a hack to keep the running animation on shallow slopes
var on_ground_cool_down = 0.0

# Player buttons
var jump = false
var move_left = false
var move_right = false
var crouch = false
var action = false

const WALK_ACCEL = 500.0
const WALK_DECEL = 1600.0
const MAX_VELOCITY = 300.0
const AIR_ACCEL = 500.0
const AIR_DECEL = 800.0
const JUMP_VELOCITY = 460.0
const STOP_JUMP_FORCE = 1500.0
const FALL_FORCE = 450.0
const BOUNCE_VELOCITY = 150.0
const BOUNCE_Y_VELOCITY = 150.0

const GROUND_COOL_DOWN = 0.1

# time in seconds
const MAGE_SHOOT_COOLDOWN = 0.3
const COW_INVISIBILITY_COOLDOWN = 1

const TANK_FALL_VEL = 40
const TANK_CRUSH_ACCEL = 5000.0

# set to the object that we can enter
var over_enterable_object = false
var enter_object

var last_checkpoint = null

const bullet = preload("res://objects/bullet/bullet.tscn")

# DAMAGE
func burn ():
	damage ()
	
func stab():
	damage()
	
func crush ():
	damage()
	
func enemy_side_hit():
	damage()
		
func damage ():
	if INVINCIBLE == state or DEAD == state or DYING == state:
		return
	if type != "":
		#undo shooting cooldown
		actioning = false
		action_cool_down = 0
		# undo cow effect
		_make_visible()
		
		_set_type("")
		$sound_hurt.play()
		$poof.play("poof")
		state = INVINCIBLE
		$invincibility_timer.start()
		$flash_timer.start()
	else:
		state = DYING
# other interactions:
func bounce (normal):
	$sound_bounce.play()
	bounce_normal = normal
	
		
func _on_flash_timer_timeout():
	visible = not visible

func _on_invincibility_timer_timeout():
	$flash_timer.stop()
	visible = true
	state = ALIVE
	
func _special_collisions (bodyState):
	for x in range(bodyState.get_contact_count()):
		var obj = bodyState.get_contact_collider_object(x)
		if (obj.has_method("is_sharp")):
			if not "tank" == type:
				damage()

#init
func _ready ():
	type = savegame.player_type


# Powerup functions
func _absorb (ground):
	var oldtype = type
	if ground.has_method("absorb"):
		var t = ground.absorb()
		_set_type(t)
	# uncoment to discard powerup when crouching on ground
	#else:
	#	actioning = false
	#	_set_type("")
		
	if (type != oldtype):
		$poof.play("poof")
		
func _set_type (t):
	type = t
	savegame.player_type = type
		
func enter_checkpoint(cp):
	if DEAD == state:
		return
	if last_checkpoint != null and last_checkpoint != cp:
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
	# consider commenting out On_ground part of this conditional.
	if move_right == move_left and on_ground:
		lv = _decelerate (lv, step, decel)
	elif move_left:
		if lv.x > 0:
			lv.x -= decel * step
		elif lv.x > -max_vel:
			lv.x -= accel * step
		elif lv.x < -max_vel:
			lv.x += decel * step
	elif move_right:
		if lv.x < 0:
			lv.x += decel * step
		elif lv.x < max_vel:
			lv.x += accel * step
		elif lv.x > max_vel:
			lv.x -= decel * step
	return lv

# player movement/acceleration when in "normal" state
# lv is linear velocity
func _normal_player_movement (lv, step):
	if bounce_normal != null:
		lv += bounce_normal * BOUNCE_VELOCITY * -1
		if bounce_normal.y > -0.7:
			lv.y -= BOUNCE_Y_VELOCITY
		else:
			lv.y += BOUNCE_Y_VELOCITY * 0.5
		bounce_normal = null
	if on_ground and crouch:
		lv = _decelerate (lv, step, WALK_DECEL)
	elif on_ground:
		lv = _apply_player_movement (lv, step, WALK_ACCEL, WALK_DECEL, MAX_VELOCITY)
	else:
		lv = _apply_player_movement (lv, step, AIR_ACCEL, AIR_DECEL, MAX_VELOCITY)
		
	lv.y = clamp(lv.y, -JUMP_VELOCITY * 1.1, JUMP_VELOCITY * 3)
	return lv
		
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
			on_ground_cool_down = GROUND_COOL_DOWN
			return x
	on_ground = false
	return -1
	
func _is_facing_right ():
	return 1 == sign($sprite.scale.x)
	
func _set_animation (lv):
	var new_anim
	if on_ground and crouch:
		new_anim = "crouch_" + type
	elif actioning and action and type != "cow":
		new_anim = "action_" + type
	elif on_ground or (not jumping and on_ground_cool_down > 0):
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
		
		
func _cow_action ():
	if action and not actioning and action_cool_down < 0:
		actioning = true
		_make_invisible()
		
	if not action and actioning:
		actioning = false
		action_cool_down = COW_INVISIBILITY_COOLDOWN
		_make_visible()
		
func _on_invisibility_timer_timeout():
	_make_visible()

func _make_invisible ():
	$sound_transform.play()
	z_index = -10
	modulate = Color(0.5, 0.8, 0.8, 1)
	$invisibility_timer.start()
	set_collision_layer_bit(7, true)
	set_collision_layer_bit(5, false)
	$poof.play("poof")
	
func _make_visible ():
	z_index = 0
	modulate = Color(1, 1, 1, 1)
	$invisibility_timer.stop()
	set_collision_layer_bit(5, true)
	set_collision_layer_bit(7, false)
	$poof.play("poof")
		
func _tank_action (body_state, lv, step):
	var floor_index = _find_ground(body_state)
	if floor_index >= 0:
		if not actioning:
			return lv
			
		actioning = false
		var ground = body_state.get_contact_collider_object(floor_index)
		if ground.has_method("crush"):
			ground.crush()
		
	elif action: #in the air
		if not actioning:
			$sound_pound.play()
		lv.y += TANK_FALL_VEL
		actioning = true
		
	elif actioning:
		lv.y += TANK_CRUSH_ACCEL * step
		
	return lv

# called during physics simulation. 
func _integrate_forces(s):
	if DEAD == state:
		return
		
	if DYING == state:
		s.set_linear_velocity(Vector2(0,0))
		if anim != "death":
			anim = "death"
			$sound_death.play()
			$anim.play("death")
		return
	
	var lv = s.get_linear_velocity()
	var step = s.get_step()
	
	action_cool_down -= step
	
	# Get the controls
	move_left = Input.is_action_pressed("move_left")
	move_right = Input.is_action_pressed("move_right")
	jump = Input.is_action_pressed("jump")
	crouch = Input.is_action_pressed("crouch")
	action = Input.is_action_pressed("action")
	var enter = Input.is_action_pressed("enter")
	
	on_ground_cool_down -= step
	
	var ground
	var floor_index = _find_ground(s)
	if floor_index >= 0:
		ground = s.get_contact_collider_object(floor_index)
	
	lv = _decompensate_ground_inertia(lv)
	_special_collisions(s)

	match type:
		"mage":
			lv = _normal_player_movement (lv, step)
			_set_animation(lv)
			_mage_action(step)
		"tank":
			lv = _normal_player_movement (lv, step)
			_set_animation(lv)
			lv = _tank_action(s, lv, step)
		"walker":
			lv = _normal_player_movement (lv, step)
			_set_animation(lv)
		"cow":
			lv = _normal_player_movement (lv, step)
			_set_animation(lv)
			_cow_action()
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
