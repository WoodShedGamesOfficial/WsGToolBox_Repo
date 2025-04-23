@tool
extends Control

var plugin : EditorPlugin = null

func _ready():
	$GridContainer/delete.button_pressed = plugin.allow_delete 
	$GridContainer/lvl_up.button_pressed = plugin.allow_lvl_up
	$GridContainer/type.button_pressed = plugin.allow_type
	$GridContainer/perfect_line.button_pressed = plugin.allow_perfect
	$GridContainer/pet.button_pressed = plugin.allow_pet

func xp_change(new_xp:int, new_max_xp:int, level:int):
	$VBoxContainer/XP_container/XP_count.text = str(new_xp) + "/" + str(new_max_xp)
	$VBoxContainer/XP_container/level.text = "Current Project Level: " + str(level)
	$VBoxContainer/TextureProgress.max_value = new_max_xp
	$VBoxContainer/TextureProgress.min_value = new_max_xp - 300
	$VBoxContainer/TextureProgress.value = new_xp

func update_settings():
	plugin.allow_delete = $GridContainer/delete.pressed
	plugin.allow_lvl_up = $GridContainer/lvl_up.pressed
	plugin.allow_type = $GridContainer/type.pressed
	plugin.allow_perfect = $GridContainer/perfect_line.pressed


func _on_pet_pressed():
	var create : bool
	
	plugin.allow_pet =! plugin.allow_pet
	
	plugin.pet_toggle(create)
	print_debug(str(plugin.allow_pet))
	
	pass
	
