@tool
extends Control

var active = false
var target:Vector2 = Vector2.ZERO

var default_speed = 1
var panic_speed = 5

var instruction = 0
#0 - stand still
#1 - heading to point
#2 - panic

func instruction_0_init():
	instruction = 0

func instruction_1_init():
	instruction = 1
	target.x = randf_range(0,get_viewport_rect().size.x)
	target.y = randf_range(0,get_viewport_rect().size.y)

func instruction_2_init():
	instruction = 2

func _ready():
	instruction_0_init()
	$AnimatedSprite.play("default")
	#mouse_entered.connect(_on_Control_mouse_entered)
	#mouse_exited.connect(_on_Control_mouse_exited)

func _process(delta):
	$AnimatedSprite.flip_h = target.x - position.x > 0
	
	if instruction == 0:
		if randf() < 0.01:
			instruction_1_init()
	
	if instruction == 1:
		position = position.move_toward(target, default_speed)
		if position == target:
			instruction_0_init()
	
	if instruction == 2:
		if randf() < 0.1:
			target.x = randf_range(0,get_viewport_rect().size.x)
			target.y = randf_range(0,get_viewport_rect().size.y)
		position = position.move_toward(target, panic_speed)
	
	if active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		position = get_global_mouse_position() - (size/2) * scale


func _on_Control_mouse_entered():
	active = true
	#print_debug("mouse touched pet slime")

func _on_Control_mouse_exited():
	active = false
