extends RefCounted
class_name InputData

var direction := 0
var jump_pressed := false
var jump_held := false
var up := false
var down_pressed := false
var down_held := false
var crouch := false
var run := false
var shoot_pressed := false
var shoot_held := false

func reset_input() -> void:
	direction = 0
	jump_pressed = false
	jump_held = false
	up = false
	down_pressed = false
	down_held = false
	crouch = false
	run = false
	shoot_pressed = false
	shoot_held = false
