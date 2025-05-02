extends Control

# Variable in order to access code in the game manager script
var game_manager_scr 

func _ready():
	pass

func _on_play_button_pressed():
	# Change to the game scene
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_options_button_pressed():
	# Show options menu
	# Could be a popup or a new scene
	pass

func _on_how_to_play_button_pressed():
	# Show how to play instructions
	# Could be a popup or a new scene
	pass

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()
