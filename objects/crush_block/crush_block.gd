extends RigidBody2D

func crush():
	$anim.play("poof")
	$collision.queue_free()