extends Node

var current_song = ""

func play (song_name):
	if song_name == current_song:
		return
	
	if current_song != "":
		get_node(current_song).stop()
	
	current_song = song_name
	if song_name != "":
		get_node(song_name).play()