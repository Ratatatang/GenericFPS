extends CharacterBody3D

const SPEED = 5.7
const SPRINT_SPEED = 6.7
const JUMP_VELOCITY = 5.6
const BOB_FREQUENCY = 2.4
const BOB_AMP = 0.05

@export var _bullet_scene : PackedScene

@onready var gunTimer = $gunTimer

@onready var gunRay = $Head/Camera3d/RayCast3d as RayCast3D
@onready var camera = $Head/Camera3d as Camera3D
@onready var gunCamera = $Head/Camera3d/Hand/SubViewportContainer/SubViewport/GunCam
@onready var hand = $Head/Camera3d/Hand

@onready var bulletCounter = $BulletCounter/BulletLabel

var mouse_relative_x = 0
var mouse_relative_y = 0

var t_bob = 0.0
var playerHeight = 0.7

var classData
var equiptGun

var itemsNum = 3

var attackHeld = false
var downSights = false
var sprinting = false

var breakReload = false

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var itemsList = {
	0: "pistol",
	1: "revolver",
	2: "assault_rifle",
	3: "shotgun"
}

var loadedItems = {
	"pistol": null,
	"revolver": null,
	"assault_rifle": null,
	"shotgun": null,
}

var currentItem = 0

func _ready():
	gunRay.add_exception(self)
	
	loadPlayerClass("res://Scenes/Player/classes/sheriffPreist.gd")
	
	for gun in itemsList.values():
		loadItemData(gun)
	
	equiptItem(itemsList.get(0))

func _process(delta):
	gunCamera.global_transform = camera.global_transform

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if Input.is_action_just_pressed("sprint"):
			sprinting = true
			
		if(sprinting):
			velocity.x = direction.x * SPRINT_SPEED
			velocity.z = direction.z * SPRINT_SPEED
		else:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		sprinting = false
	
	#Head Bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(t_bob)
	
	move_and_slide()
	
	if(attackHeld):
		if(gunTimer.is_stopped() == true):
				if(equiptGun.bullets >= 1):
					equiptGun.bullets -= 1
					bulletCounter.text = str(equiptGun.bullets) + "/" + str(equiptGun.maxBullets)
					SFXHandler.playSFX(equiptGun.fireSound, self)
					equiptGun.animator.play("fire")
					gunTimer.start()
					
					for i in equiptGun.bulletPattern:
						gunRay.rotation += Vector3(
							i.x/25+randf_range(-equiptGun.spread/25, equiptGun.spread/25), 
							i.y/25+randf_range(-equiptGun.spread/25, equiptGun.spread/25), 0)
						gunRay.force_raycast_update()
						shoot()
						gunRay.rotation = Vector3.ZERO

func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMP + playerHeight
	return pos

func _input(event):
	if event is InputEventMouseMotion:
		var sensitivity = 1000-GlobalSettings.MouseSensitivity
		rotation.y -= event.relative.x / sensitivity
		camera.rotation.x -= event.relative.y / sensitivity
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		mouse_relative_x = clamp(event.relative.x, -50, 50)
		mouse_relative_y = clamp(event.relative.y, -50, 10)
	
	if(equiptGun.fireMode == 0):
		if event.is_action_pressed("attack"):
			breakReload = true
			if(gunTimer.is_stopped() == true):
				if(equiptGun.bullets >= 1):
					equiptGun.bullets -= 1
					
					bulletCounter.text = str(equiptGun.bullets) + "/" + str(equiptGun.maxBullets)
					
					SFXHandler.playSFX(equiptGun.fireSound, self)
					equiptGun.animator.play("fire")
					gunTimer.start()
					
					for i in equiptGun.bulletPattern:
						gunRay.rotation += Vector3(
							i.x/25+randf_range(-equiptGun.spread, equiptGun.spread), 
							i.y/25+randf_range(-equiptGun.spread, equiptGun.spread), 0)
							
						gunRay.force_raycast_update()
						shoot()
						gunRay.rotation = Vector3.ZERO
				
				else:
					SFXHandler.playSFX(equiptGun.emptySound, self)
					
	elif(equiptGun.fireMode == 1):
		if(event.is_action_pressed("attack")):
			breakReload = true
			attackHeld = true
			if(equiptGun.bullets < 1):
				SFXHandler.playSFX(equiptGun.emptySound, self)
				
		if(event.is_action_released("attack")):
			attackHeld = false
	
	if(event.is_action_pressed("altMouse")):
		downSights = true
		await equiptGun.animator.animation_finished
		equiptGun.animator.play("sights")
	
	elif(event.is_action_released("altMouse")):
		downSights = false
		await equiptGun.animator.animation_finished
		equiptGun.animator.play("sights")
				
	if event.is_action_pressed("reload") and gunTimer.is_stopped() and !equiptGun.bullets >= equiptGun.maxBullets:
		breakReload = false
		if(equiptGun.loadingMode == 0):
			gunTimer.wait_time = equiptGun.reloadRate
			gunTimer.start()
			SFXHandler.playSFX(equiptGun.reloadSound, self)
		
			await gunTimer.timeout
		
			gunTimer.wait_time = equiptGun.fireRate
			equiptGun.bullets = equiptGun.maxBullets
			bulletCounter.text = str(equiptGun.bullets) + "/" + str(equiptGun.maxBullets)
		elif(equiptGun.loadingMode == 1):
			while(true):
				if(breakReload or equiptGun.bullets >= equiptGun.maxBullets):
					gunTimer.wait_time = equiptGun.ReloadFinishTime
					gunTimer.start()
					SFXHandler.playSFX(equiptGun.loadFinishedSound, self)
					break
				elif(equiptGun.bullets < equiptGun.maxBullets):
					gunTimer.wait_time = equiptGun.reloadRate
					gunTimer.start()
					SFXHandler.playSFX(equiptGun.reloadSound, self)
				
					await gunTimer.timeout
				
					gunTimer.wait_time = equiptGun.fireRate
					equiptGun.bullets += 1
					bulletCounter.text = str(equiptGun.bullets) + "/" + str(equiptGun.maxBullets)
		breakReload = false
			
	if(!gunTimer.is_stopped()):
		pass
	
	elif event.is_action_pressed("num1"):
		currentItem = 0
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("num2"):
		currentItem = clamp(1, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
		
	elif event.is_action_pressed("num3"):
		currentItem = clamp(2, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("num4"):
		currentItem = clamp(3, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("num5"):
		currentItem = clamp(4, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("num6"):
		currentItem = clamp(5, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("num7"):
		currentItem = clamp(6, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("num8"):
		currentItem = clamp(7, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("num9"):
		currentItem = clamp(8, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("num0"):
		currentItem = clamp(9, 0, itemsNum)
		equiptItem(itemsList.get(currentItem))
		
	
	elif event.is_action_pressed("scrollDown"):
		currentItem -= 1
		
		if(currentItem < 0):
			currentItem = itemsNum
		equiptItem(itemsList.get(currentItem))
	
	elif event.is_action_pressed("scrollUp"):
		currentItem += 1
		
		if(currentItem > itemsNum):
			currentItem = 0
		equiptItem(itemsList.get(currentItem))

func loadPlayerClass(className):
	classData = load(className).new()
	itemsList = classData.items
	itemsNum = classData.itemsNum
	loadedItems.clear()
	
	for value in itemsList.values():
		loadedItems.merge({value: null})

func loadItemData(itemName):
	var itemInstance = load("res://Scenes/Player/Guns/%s.tscn" % itemName).instantiate()
	hand.add_child(itemInstance)
	itemInstance.visible = false
	
	itemInstance.bullets = itemInstance.maxBullets
	
	loadedItems[itemName] = itemInstance

func equiptItem(itemName):
	attackHeld = false
	
	if(equiptGun != null):
		equiptGun.visible = false
	
	equiptGun = loadedItems.get(itemName)
	equiptGun.visible = true
	
	hand.swayLeft = equiptGun.swayLeft
	hand.swayRight = equiptGun.swayRight
	hand.swayNormal = equiptGun.swayNormal
	
	gunTimer.wait_time = equiptGun.fireRate
	
	bulletCounter.text = str(equiptGun.bullets) + "/" + str(equiptGun.maxBullets)

func shoot():
	if(equiptGun.bulletType == 0):
		if not gunRay.is_colliding():
			return
	
		var bulletInst = _bullet_scene.instantiate() as Node3D
		bulletInst.set_as_top_level(true)
		get_parent().add_child(bulletInst)
		bulletInst.global_transform.origin = gunRay.get_collision_point() as Vector3
		bulletInst.look_at((gunRay.get_collision_point()+gunRay.get_collision_normal()),Vector3.BACK)
		print(gunRay.get_collision_point())
		
	elif(equiptGun.bulletType == 1):
		pass
