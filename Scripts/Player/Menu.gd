extends CanvasLayer

@onready var menu = $Menu
@onready var settings = $Settings
@onready var multiplayerScreen = $Multiplayer

@onready var screens = [settings, multiplayerScreen]

enum ScreenLoaded {NOTHING, JUST_MENU, SETTINGS, MULTIPLAYER}
var screenLoaded = ScreenLoaded.NOTHING

var enabled = true

func _ready():
	visible = false

func _input(event) -> void:
	if event.is_action_pressed("menu"):
		reloadScreens("menu")

func reloadScreens(event):
	if(enabled == false and screenLoaded == ScreenLoaded.NOTHING):
		visible = false
		return
	match screenLoaded:
		ScreenLoaded.NOTHING:
			if event == "menu":
				visible = true
				hideAll()
				screenLoaded = ScreenLoaded.JUST_MENU
		
		ScreenLoaded.JUST_MENU:
			if event == "menu":
				visible = false
				screenLoaded = ScreenLoaded.NOTHING
			if event == "reload":
				hideAll()
				menu.visible = true
		
		ScreenLoaded.SETTINGS:
			if event == "menu":
				visible = false
				screenLoaded = ScreenLoaded.NOTHING
			if event == "reload":
				hideAll()
				settings.visible = true
		
		ScreenLoaded.MULTIPLAYER:
			if event == "menu":
				visible = false
				screenLoaded = ScreenLoaded.NOTHING
			if event == "reload":
				hideAll()
				multiplayerScreen.visible = true

func hideAll():
	for screen in screens:
		screen.visible = false

func _on_settings_pressed():
	screenLoaded = ScreenLoaded.SETTINGS
	reloadScreens("reload")

func _on_multiplayer_pressed():
	screenLoaded = ScreenLoaded.MULTIPLAYER
	reloadScreens("reload")
