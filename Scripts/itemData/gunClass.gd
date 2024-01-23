extends weapon
class_name gunClass

enum bulletTypes {
	HITSCAN,
	PROJECTILE
}

enum fireModes {
	SINGLE_FIRE,
	AUTO_FIRE,
	BURST_FIRE
}

@export var bulletType : bulletTypes
@export var fireMode : fireModes
@export var fireRate : float
@export var maxBullets : int
@export var reloadRate : float
@export var spread : float = 0
@export var bulletPattern : Array[Vector2] = [Vector2.ZERO]

@export var fireSound : AudioStreamWAV = load("res://Assets/Guns/SFX/PistolFire.wav")
@export var emptySound = load("res://Assets/Guns/SFX/DryFire.wav")
@export var reloadSound = load("res://Assets/Guns/SFX/Reload.wav")

@export_node_path var animator_path : NodePath
@onready var animator = get_node(animator_path)

var bullets = maxBullets
