extends Node3D

var mouseMove
var swayThreshold = 5
var swayLerp = 2

var swayLeft = Vector3(0, 0.1, 0)
var swayRight = Vector3(0, -0.1, 0)
var swayNormal = Vector3(0, 0, 0)

func _input(event):
	if(event is InputEventMouseMotion):
		mouseMove = -event.relative.x

func _physics_process(delta):
	if(mouseMove != null):
		if mouseMove > swayThreshold:
			rotation = rotation.lerp(swayRight, swayLerp * delta)
		elif mouseMove < -swayThreshold:
			rotation = rotation.lerp(swayLeft, swayLerp * delta)
		else:
			rotation = rotation.lerp(swayNormal, swayLerp * delta)

