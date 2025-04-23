@tool
extends EditorPlugin

var text_editors = []
const TYPE_EFFECT_P = preload("res://addons/WsG_Docker/effects/type_effect.tscn")
const LVL_UP_VFX_P = preload("res://addons/WsG_Docker/effects/lvl_up.tscn")
const DELETE_VFX_P = preload("res://addons/WsG_Docker/effects/delete.tscn")
const PERFECT_LINE_P = preload("res://addons/WsG_Docker/effects/perfect_line.tscn")
const SLIMEY_P = preload("res://addons/WsG_Docker/effects/pet.tscn")
var slime : Control
var dock : Control
var last_key = "a"
var last_line = 0
var perfect = true

#user vars
var xp:int = 0
var lvl:int = 1
var max_xp:int = 300

@onready var allow_delete = true 
@onready var allow_lvl_up = true 
@onready var allow_type = true 
@onready var allow_perfect = true 
@onready var allow_pet = true

#shake vars
var root = get_editor_interface().get_base_control()
var intensity:float = 0
var timer:float

#preferences
var user_config:ConfigFile = ConfigFile.new()


#VVVVVVVVVVVVVVVVVVVVVV                VVVVVVVVVVVVVVVVVVV          VVVVVVVVVVVVV


func _enter_tree():
	print("WsGDocker init...")
	
	#user data load
	user_config.load("user://WsG_Dev_Docker_config.ini")
	xp = user_config.get_value("xp", "xp", 0)
	lvl = int(xp/300)+1
	max_xp = lvl * 300
	
	allow_delete = user_config.get_value("settings", "allow_delete", true)
	allow_lvl_up = user_config.get_value("settings", "allow_lvl_up", true)
	allow_type = user_config.get_value("settings", "allow_type", true)
	allow_perfect = user_config.get_value("settings", "allow_perfect", true)
	allow_pet = user_config.get_value("settings", "allow_pet", true)
	
	get_editor_interface().get_script_editor().editor_script_changed.connect(editor_script_changed)
	
	reload()
	
	if text_editors == null:
		push_error("could not initialize plugin.")
		return
	
	dock = preload("res://addons/WsG_Docker/dock_panel.tscn").instantiate()
	dock.plugin = self
	add_control_to_bottom_panel(dock, "WsG")
	dock.xp_change(xp, max_xp, lvl)
	
	if allow_pet:
		slime = SLIMEY_P.instantiate()
		get_editor_interface().get_base_control().add_child(slime)
	
	pass
	



func reload():
	print_debug("script_reloaded, here we go baby!")
	text_editors.clear()
	find_text_edit(get_editor_interface().get_script_editor())
	for element in text_editors:
		if not element.is_connected('text_changed', text_changed):
			element.text_changed.connect(text_changed.bind(element))
			element.gui_input.connect(gui_input)
	
	pass
	



func editor_script_changed(script:Script):
	reload()
	
	pass
	



func find_text_edit(node:Node):
	for element in node.get_children():
		if element is TextEdit:
			text_editors.append(element)
		else:
			find_text_edit(element)
	
	pass
	



func _exit_tree():
	remove_control_from_bottom_panel(dock)
	dock.queue_free()
	slime.queue_free()
	
	pass
	



func get_cursor_pos(text_editor:TextEdit)->Vector2:
	var settings = get_editor_interface().get_editor_settings()
	
	var line = text_editor.get_caret_line()
	var column = text_editor.get_caret_column()
	
	# Compensate for code folding
	var folding_adjustment = 0
	for i in line:
		if text_editor.is_caret_visible(i):
			folding_adjustment += 1

	# Compensate for tab size
	var tab_size = settings.get_setting("text_editor/indent/size")
	var line_text = text_editor.get_line(line).substr(0,column)
	column += line_text.count("\t") * (tab_size - 1)

	# Compensate for scroll
	var vscroll = text_editor.scroll_vertical
	var hscroll = text_editor.scroll_horizontal
	
	# Compensate for line spacing
	var line_spacing = settings.get_setting("text_editor/theme/line_spacing")
	
	# compensate fontsize
	var fontsize = text_editor.get_font("font").get_string_size(" ")
	
	# Compensate for editor scaling
	var scale = get_editor_interface().get_editor_scale()

	# Compute gutter width in characters
	var line_count = text_editor.get_line_count()
	var gutter = str(line_count).length() + 6
	
	# Compute caret position
	var pos = Vector2()
	pos.x = (gutter + column) * fontsize.x * scale - hscroll
	pos.y = (line - folding_adjustment - vscroll) * (fontsize.y + line_spacing)
	pos.y *= scale
	
	return pos
	



func text_changed(text_editor : TextEdit):
	type_effect(text_editor)
	
	var current_line = text_editor.get_caret_line()
	var prev_line_text = text_editor.get_line(last_line)
	
	if last_key == "Enter" and current_line == last_line + 1:
		if perfect and prev_line_text.dedent() != "":
			perfect_effect(text_editor)
		perfect = true
	
	last_line = text_editor.get_caret_line(last_line)
	
	if last_key == "BackSpace" or last_key == "Delete":
		perfect = false
		delete_effect(text_editor)
	else:
		xp_increase(1)
	
	pass
	



func perfect_effect(text_editor:TextEdit):
	if not allow_perfect:
		return
	
	var effect = PERFECT_LINE_P.instantiate()
	text_editor.add_child(effect)
	
	var pos = get_cursor_pos(text_editor)
	effect.position = pos
	effect.init()
	
	pass
	



func type_effect(text_editor : TextEdit):
	if not allow_type:
		return
	
	var effect = TYPE_EFFECT_P.instantiate()
	text_editor.add_child(effect)
	
	var pos = text_editor.get_caret_draw_pos() + Vector2(-15, -30)
	
	effect.position = pos
	effect.init(last_key)
	
	pass



func xp_increase(amount:int):
	xp+=amount
	if xp>=max_xp:
		lvl+=1
		max_xp=lvl*300
		
		lvl_up_effect()
	
	dock.xp_change(xp, max_xp, lvl)
	
	pass
	



func apply_changes():
	user_config.set_value("xp", "xp", xp)
	
	user_config.set_value("settings", "allow_delete", allow_delete)
	user_config.set_value("settings", "allow_lvl_up", allow_lvl_up)
	user_config.set_value("settings", "allow_type", allow_type)
	user_config.set_value("settings", "allow_perfect", allow_perfect)
	user_config.set_value("settings", "allow_pet", allow_pet)
	
	user_config.save("user://WsG_Dev_Docker_config.ini")
	
	pass
	



func lvl_up_effect():
	if not allow_lvl_up:
		return
	shake(10,0.5)
	var effect = LVL_UP_VFX_P.instantiate()
	get_editor_interface().get_editor_viewport().add_child(effect)
	effect.position.x = randf_range(0, get_editor_interface().get_editor_viewport ().size.x)
	effect.position.y = randf_range(0, get_editor_interface().get_editor_viewport ().size.y)
	
	pass
	



func delete_effect(text_editor:TextEdit):
	if not allow_delete:
		return
	var effect = DELETE_VFX_P.instantiate()
	text_editor.add_child(effect)
	effect.position = text_editor.get_caret_draw_pos()
	effect.init(last_key)
	
	pass
	



func shake(intens:float, dur:float):
	intensity = intens
	timer = dur
	
	pass
	



func _process(delta):
	if timer > 0:
		root.position.x = randf_range(-intensity, intensity)
		root.position.y = randf_range(-intensity, intensity)
		timer-=delta
		
		if timer <=0:
			root.position = Vector2.ZERO
	
	pass
	



func gui_input(event:InputEvent):
	if event is InputEventKey and event.pressed:
		last_key = OS.get_keycode_string(event.get_keycode_with_modifiers())
	
	pass
	



func pet_toggle(create:bool):
	create = allow_pet
	
	if create:
		slime = SLIMEY_P.instantiate()
		get_editor_interface().get_base_control().add_child(slime)
		
	else:
		for slimes in get_editor_interface().get_base_control().get_children():
			if slimes == slime:
				slimes.queue_free()
	
	pass
	
