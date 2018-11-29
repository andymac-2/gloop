extends RigidBody2D

func crush():
	$anim.play("poof")
	$sound_destroy.play()
	$collision.queue_free()