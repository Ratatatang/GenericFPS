extends Node

func playSFX(sound : AudioStream, parent : Node):
	var stream = AudioStreamPlayer.new()
	
	stream.stream = sound
	stream.volume_db = linear_to_db(GlobalSettings.SFXVolume)
	parent.add_child(stream)
	stream.play()
