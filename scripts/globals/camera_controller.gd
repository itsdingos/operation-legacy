extends Node

enum FollowMode {
	NODE,
	POSITION
}

var follow_mode:FollowMode = FollowMode.POSITION

var camera:Camera2D
var target_node:Node2D
var target_position:Vector2
var camera_offset:Vector2
@export var camera_offset_speed:float = 0.65

@export_category("TraumaShaking")
var trauma := 0.0

@export var trauma_decay:float = .8
@export var max_shake_offset:Vector2 = Vector2(20.0, 15.0)
@export var noise_speed:float = 90.0

var _noise:FastNoiseLite
var _noise_time:float

func _process(delta: float) -> void:
	if !is_instance_valid(camera):
		printerr("No camera created, please use refresh() at main scene _ready loading.")
		return
	
	match follow_mode:
		FollowMode.NODE:
			if is_instance_valid(target_node):
				target_position = target_node.global_position
				
				if target_node.has_method("get_camera_offset"):
					var camera_offset_distance:Vector2 = target_node.get_camera_offset()
					
					camera_offset = camera_offset.lerp(
						camera_offset_distance,
						1.0 - exp(-camera_offset_speed * delta)
					)
				
				else:
					camera_offset = Vector2.ZERO
		
		FollowMode.POSITION:
			pass
	
	camera.global_position = target_position + camera_offset
	camera.offset = _get_clamped_shake_offset()
	
	trauma = lerpf(trauma, 0.0, trauma_decay * delta)
	_noise_time += delta + noise_speed

func refresh(current_scene:LevelSettings) -> void:
	if !is_instance_valid(camera):
		_create_camera()
	
	camera.set_limit(SIDE_TOP, 0)
	camera.set_limit(SIDE_LEFT, 0)
	camera.set_limit(SIDE_BOTTOM, current_scene.world_size.y)
	camera.set_limit(SIDE_RIGHT, current_scene.world_size.x)
func snap() -> void:
	if is_instance_valid(target_node):
		target_position = target_node.global_position
	
	camera.global_position = target_position
	
	camera.reset_smoothing()
func follow(node:Node2D) -> void:
	if is_instance_valid(node):
		target_node = node
		follow_mode = FollowMode.NODE
func set_target_position(position:Vector2) -> void:
	follow_mode = FollowMode.POSITION
	target_position = position
	camera_offset = Vector2.ZERO
func shake(new_trauma: float) -> void:
	trauma = clampf(trauma + new_trauma, 0.0, 1.0)

func _create_camera() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	
	camera = Camera2D.new()
	
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	
	get_tree().current_scene.add_child.call_deferred(camera)
func _get_shake_offset() -> Vector2:
	if trauma == 0.0:
		return Vector2.ZERO
	
	var intensity: float = trauma * trauma
	return Vector2(
		_noise.get_noise_2d(_noise_time, 0.0) * max_shake_offset.x * intensity,
		_noise.get_noise_2d(0.0, _noise_time) * max_shake_offset.y * intensity
	)
func _get_clamped_shake_offset() -> Vector2:
	var raw := _get_shake_offset()
	if raw == Vector2.ZERO:
		return Vector2.ZERO
	
	var half_vp := get_viewport().get_visible_rect().size * 0.5 / camera.zoom
	
	var slack_right := maxf(camera.limit_right  - (target_position.x + half_vp.x), 0.0)
	var slack_left  := maxf((target_position.x  - half_vp.x) - camera.limit_left,  0.0)
	var slack_down  := maxf(camera.limit_bottom - (target_position.y + half_vp.y), 0.0)
	var slack_up    := maxf((target_position.y  - half_vp.y) - camera.limit_top,   0.0)
	
	return Vector2(
		clampf(raw.x, -slack_left, slack_right),
		clampf(raw.y, -slack_up,   slack_down)
	)

#
#func _process(delta: float) -> void:
	#if !is_instance_valid(camera):
		#printerr("No camera created, please use refresh() at main scene _ready loading.")
		#return
	#
	#if is_instance_valid(target_node):
		#var desired_sign := lookahead_sign
		#var desired_distance := lookahead_distance
		#var desired_speed := lookahead_speed
		#
		#if target_node is Soldier:
			#var soldier := target_node as Soldier
			#var state:String = soldier.state_machine.current_state
			#
			#match state:
				#"hang":
					#desired_sign = lookahead_sign
					#desired_distance *= hang_lookahead_multiplier
					#desired_speed = 2.0
				#
				#"wall_jump", "jump":
					#if abs(soldier.velocity.x) > 20.0:
						#desired_sign = sign(soldier.velocity.x)
					#desired_speed = air_lookahead_speed
				#
				#"fall":
					#pass
				#
				#_:
					#if soldier.input.direction != 0:
						#desired_sign = soldier.input.direction
					#else:
						#desired_sign = soldier.direction
		#
		#lookahead_sign = desired_sign
		#
		#var desired_lookahead := Vector2(lookahead_sign * desired_distance, 0.0)
		#lookahead_offset = lookahead_offset.lerp(
			#desired_lookahead,
			#1.0 - exp(-desired_speed * delta)
		#)
	#
	#target_position = target_node.global_position + lookahead_offset
	#
	#camera.global_position = target_position
	#camera.offset = _get_clamped_shake_offset()
	#
	#trauma = maxf(trauma - trauma_decay * delta, 0.0)
	#_noise_time += delta * noise_speed
