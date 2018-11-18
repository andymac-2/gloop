extends RigidBody2D

func burn():
	$anim.play("poof")
	$collision.queue_free()