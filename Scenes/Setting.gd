extends Control

func updateSettings():
	GlobalSettings.SFXVolume = $VolumeSlider.value
	GlobalSettings.MouseSensitivity = $MouseSensitivity.value
