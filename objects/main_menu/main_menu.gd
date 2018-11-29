extends CanvasLayer

enum STATE {
	NEWGAME,
	CONTINUE
}

var has_game = false
var state = CONTINUE

func _ready():
	has_game = savegame.file_exists()
	if not has_game:
		$continue_label.modulate = Color(0.5, 0.5, 0.5)
		
func _process(delta):
	var move_left = Input.is_action_just_pressed("move_left")
	var move_right = Input.is_action_just_pressed("move_right")
	var crouch = Input.is_action_just_pressed("crouch")
	var action = Input.is_action_just_pressed("enter")
	
	var jump = Input.is_action_just_released("jump")
	
	var swap = move_left or move_right or crouch or action
	
	if swap:
		$sound_move.play()
		if state == CONTINUE:
			$anim.play("move_down")
			state = NEWGAME
		elif state == NEWGAME:
			$anim.play("move_up")
			state = CONTINUE
			
	if jump:
		if state == CONTINUE and has_game:
			$sound_select.play()
			savegame.start_game()
		if state == NEWGAME:
			$sound_select.play()
			savegame.new_game()