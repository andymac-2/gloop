extends RigidBody2D

func burn():
	$anim.play("poof")
	$sound_destroy.play()
	$collision.queue_free()