extends RigidBody2D

enum STATE {
	ACTIVE,
	DISABLED
}
var state = ACTIVE

func _pre_die():
	if DISABLED == state:
		return
	state = DISABLED
	$collider.queue_free()
	$anim.play("shutdown")

func _ready():
	$anim.play("go")
	$active_timer.start()

func _on_bullet_body_entered(body):
	if ACTIVE == state and body.has_method("burn"):
		body.burn()
		_pre_die()
