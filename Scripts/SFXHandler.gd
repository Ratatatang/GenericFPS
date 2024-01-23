extends Node

func playSFX(sound : AudioStream, parent : Node):
	var stream = AudioStreamPlayer.new()
	
	stream.stream = sound
	parent.add_child(stream)
	stream.play()
