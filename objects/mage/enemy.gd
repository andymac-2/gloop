extends RigidBody2D

# Member variables
enum STATE {
	WALKING,
	STOPPED,
	SHOOTING,
	DYING
}

var state = WALKING

var direction = -1
var anim = ""

onready var rc_left = $raycast_left
onready var rc_right = $raycast_right

var WALK_SPEED = 50

const bullet = preload("res://objects/bullet/bullet.tscn")

func _pre_die():
	if DYING == state:
		return
		
	state = DYING
	
	$anim.play("poof")
	$shape1.queue_free()
	$shape2.queue_free()
	$shape3.queue_free()
	$shape4.queue_free()
	
	$sound_explode.play()
	$death_timer.start()
	
	
func absorb():
	_pre_die ()
	return "mage"
	
func burn ():
	_pre_die()
	
func _is_facing_right ():
	return 1 == sign($sprite.scale.x)
	
func _pause_and_shoot ():
	state = SHOOTING
	anim = "shoot"
	$anim.play("shoot")
	
func _shoot ():
	var bi = bullet.instance()
	var ss
	if _is_facing_right():
		ss = 1.0
	else:
		ss = -1.0
	var pos = position + $bullet_shoot.position * Vector2(ss, 1.0)
		
	bi.position = pos
	get_parent().add_child(bi)
		
	var FIREBALL_VELOCITY = 250.0
	bi.linear_velocity = Vector2(FIREBALL_VELOCITY * -ss, -20)
	
	bi.set_collision_mask_bit(5, true)
	state = WALKING

func _integrate_forces(s):
	if state != WALKING:
		s.set_linear_velocity(Vector2(0,0))
		return
	
	var lv = s.get_linear_velocity()

	var new_anim = "walk"
	
	var wall_side = 0.0
	
	for i in range(s.get_contact_count()):
		var cc = s.get_contact_collider_object(i)
		var dp = s.get_contact_local_normal(i)
		
		if dp.x > 0.8:
			wall_side = 1.0
		elif dp.x < -0.8:
			wall_side = -1.0
	
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
	
	if anim != new_anim:
		anim = new_anim
		$anim.play(anim)
	
	s.set_linear_velocity(lv)
