extends Area2D

export var text = "Insert your text here."

func _ready():
	$text_parent/label.text = text
	$idle.play("idle")

# The mask and layer options are set so that only the player activates the signs.
func _on_Sign_body_entered(body):
	$anim.play("show")

func _on_Sign_body_exited(body):
	$anim.play("hide")