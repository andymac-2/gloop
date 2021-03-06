extends RigidBody2D

enum STATE {
	ALIVE,
	DYING
}

var direction = 1
var anim = ""
var state = ALIVE

const WALK_SPEED = 50

onready var rc_left = $raycast_left
onready var rc_right = $raycast_right

func _pre_die():
	if DYING == state:
		return
		
	state = DYING
	
	$anim.play("poof")
	$sound_die.play()
	$shape1.queue_free()
	$shape2.queue_free()
	
func absorb():
	_pre_die()
	return "walker"
	
func burn ():
	_pre_die()
	
func crush ():
	_pre_die()

func _integrate_forces(s):
	if state != ALIVE:
		s.set_linear_velocity(Vector2(0,0))
		return
	
	var lv = s.get_linear_velocity()

	var new_anim = "rolling"
	var wall_side = 0.0
	
	for i in range(s.get_contact_count()):
		var cc = s.get_contact_collider_object(i)
		var dp = s.get_contact_local_normal(i)

		if dp.y < 0.3:
			var obj = s.get_contact_collider_object(i)
			if obj.has_method("bounce"):
				obj.bounce(dp)
		
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
