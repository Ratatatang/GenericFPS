extends Node3D

@onready var screenEffects = $ScreenEffects/AnimationPlayer
@onready var world = $World

var gamePaused = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if(event.is_action_pressed("menu")):
		if(gamePaused):
			screenEffects.play("fadeFromPause")
			gamePaused = false
			world.process_mode = Node.PROCESS_MODE_INHERIT
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			gamePaused = true
			screenEffects.play("fadeToPause")
			world.process_mode = Node.PROCESS_MODE_DISABLED
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
