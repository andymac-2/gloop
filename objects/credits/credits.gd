extends CanvasLayer

export var song = ""

func _ready():
	music.play(song)
	$anim.play("roll")