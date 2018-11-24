extends CanvasLayer

func _ready():
	$anim.play("rotate")
	
func update_hud():
	update_green_gem_count(savegame.green_gem_total)
	update_blue_gem_count(savegame.crystal_total)
	update_key_count(savegame.key_total)
	
func update_green_gem_count(num):
	$green_gem/label.text = "x " + String(num)
	
func update_blue_gem_count(num):
	$blue_gem/label.text = "x " + String(num)
	
func update_key_count(num):
	$key/label.text = "x " + String(num)
	

