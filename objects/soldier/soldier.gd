extends CharacterBody2D
class_name Soldier

@warning_ignore("unused_signal")
signal death(node)

enum ControllerType {
	DUMMY,
	PLAYER,
	ALLY,
	ENEMY
}

enum Stance {
	STAND,
	RUN,
	CROUCH,
	AIR
}

@export var controller_type:ControllerType

@export_category("Base Definitions")

@export var max_hp:float = 100
@export var base_lookahead_distance:float

@export_subgroup("Grounded Movement Settings")
@export var ground_base_speed := 100.0
@export var ground_base_accel := 800.0
@export var base_jump_height := 32
@export_range(0.0, 1.0, .01) var weight_ratio:float

@export_subgroup("Air Movement Settings")
@export var air_base_speed := 260.0
@export var air_base_accel := 120.0
@export var max_fall_speed := 2600.0

@export_subgroup("Ledge Grabbing Settings")
@export var ledge_grab_forward_offset := Vector2.ZERO
@export var ledge_grab_distance := 10
@export var ledge_grab_threshold := 12

@export_subgroup("Buffers", "buffer_")
@export var buffer_jump_time := 0.05
@export var buffer_coyote_time_max := 0.05

@onready var sprite := $Sprite2D
@onready var stand_collider := $CollisionStand
@onready var crouch_collider := $CollisionCrouch
@onready var stand_hurtbox := $HurtboxStand
@onready var crouch_hurtbox := $HurtboxCrouch
@onready var state_machine := $StateMachine
@onready var gun := $Gun

var hp:float

var is_shooting:bool
var allow_input:bool = true

var stance:Stance

var stand_width:float
var stand_height:float
var crouch_width:float
var crouch_height:float

var current_collider:CollisionShape2D
var current_hurtbox:Hurtbox

var speed_multiplier := 1.0
var accel_multiplier := 1.0
var default_surface:= preload("res://definitions/surfaces/default.tres")
var surface:SurfaceData = default_surface
var last_floor_normal := Vector2.UP
var surface_velocity:Vector2
var last_ledge_grabbed:Vector2

var controller:DummyController
var input := InputData.new()
@export var direction := 1 :
	set(value):
		if value == 0:
			return
		
		direction = sign(value)
		
		if is_instance_valid(sprite): sprite.scale.x = abs(sprite.scale.x) * direction
var gravity := GameManager.GRAVITY

var jump_buffer:float
var coyote_time:float

var desired_camera_offset := Vector2.ZERO

func _ready() -> void:
	hp = max_hp
	
	#Adding safe margin for collision checks at the begining of a level.
	position.y += safe_margin
	
	stand_collider.disabled = false
	crouch_collider.disabled = true
	current_collider = stand_collider
	current_hurtbox = stand_hurtbox
	
	stand_width = stand_collider.shape.size.x
	stand_height = stand_collider.shape.size.y
	crouch_width = crouch_collider.shape.size.x
	crouch_height = crouch_collider.shape.size.y
	
	gun.owner_ref = self
	
	match controller_type:
		ControllerType.DUMMY:
			controller = DummyController.new()
		
		ControllerType.PLAYER:
			controller = PlayerController.new()
		
		ControllerType.ALLY:
			controller = DummyController.new()
			push_warning("AllyController not implemented, using Dummy")
		
		ControllerType.ENEMY:
			controller = EnemyController.new()
	
	if GameManager.debug == GameManager.DebugTypes.VISUAL:
		state_machine.debug = true

func _physics_process(delta: float) -> void:
	printt(
		"physical:", get_physics_process_delta_time(),
		"visual:", get_process_delta_time())
	#var frame := Engine.get_physics_frames()
#
	#print(
		#"frame: ", frame,
		#" | on_floor: ", is_on_floor(),
		#" | jump_buffer: ", jump_buffer,
		#" | state: ", state_machine.current_state
	#)
	
	update_input()
	
	_handle_jump_buffer(delta)
	_handle_coyote_time(delta)
	
	state_machine.physics_update(delta)
	
	queue_redraw()

# --- Helper Functions ---

func update_surface() -> void:
	surface = default_surface
	
	if !is_on_floor():
		return
	
	var result := _cast_ray(global_position, -up_direction * floor_snap_length * 2)
	
	if result:
		var collider:CollisionObject2D = result.collider
		
		if collider.has_meta("surface"):
			surface = collider.get_meta("surface")
func update_input() -> void:
	if !allow_input:
		input.reset_input()
		return
	
	controller.update_input(input)
func can_fit_at(pos: Vector2, shape:Shape2D) -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	
	params.shape = shape
	params.transform = Transform2D(0, pos)
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]
	
	return GameManager.space_state_ref.intersect_shape(params).is_empty()
func set_standing() -> void:
	if current_hurtbox == stand_hurtbox: return
	$ColorRect.scale.y = 1.0
	
	speed_multiplier = 1.0
	accel_multiplier = 1.0
	
	crouch_collider.disabled = true
	stand_collider.disabled = false
	current_collider = stand_collider
	
	stand_hurtbox.remaining_iframes = crouch_hurtbox.remaining_iframes
	
	crouch_hurtbox.disabled = true
	stand_hurtbox.disabled = false
	current_hurtbox = stand_hurtbox
func set_crouching() -> void:
	if current_hurtbox == crouch_hurtbox: return
	$ColorRect.scale.y = 0.7
	
	speed_multiplier = 0.3
	accel_multiplier = 0.5
	
	crouch_collider.disabled = false
	stand_collider.disabled = true
	current_collider = crouch_collider
	
	crouch_hurtbox.remaining_iframes = stand_hurtbox.remaining_iframes
	
	crouch_hurtbox.disabled = false
	stand_hurtbox.disabled = true
	current_hurtbox = crouch_hurtbox
func can_stand() -> bool:
	return can_fit_at(global_position + stand_collider.position, stand_collider.shape)
func try_stand() -> void:
	if can_stand():
		set_standing()
	
	else:
		set_crouching()
func is_crouching() -> bool:
	return current_collider == crouch_collider

func get_lookahead_vector() -> Vector2:
	return Vector2(base_lookahead_distance, 0)
func get_camera_offset() -> Vector2:
	return desired_camera_offset * direction

# --- Movement ---

func handle_movement(delta:float) -> void:
	if is_on_floor():
		direction = input.direction
		_handle_ground_movement(delta)
	
	else:
		_handle_air_movement(delta)
func _handle_ground_movement(delta) -> void:
	var max_speed := get_effective_max_speed()
	var accel := ground_base_accel * surface.acceleration * _calculate_weight(1.0, .7) * accel_multiplier
	
	if input.direction != 0:
		velocity.x = move_toward(
			velocity.x,
			input.direction * max_speed,
			accel * delta
		)
		
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			accel * surface.friction * delta
		)
	
	velocity += surface_velocity
func _handle_air_movement(delta) -> void:
	var max_speed := get_effective_max_speed()
	
	velocity.x = move_toward(
		velocity.x,
		input.direction * max_speed,
		air_base_accel * _calculate_weight(1.0, 0.6) * delta
	)
func get_jump_velocity() -> Vector2:
	var origin := global_position
	var target := global_position + (-up_direction) * 16
	
	var query := PhysicsRayQueryParameters2D.create(
		origin,
		target,
		collision_mask,
		[get_rid()]
	)
	
	var result := GameManager.space_state_ref.intersect_ray(query)
	var normal := up_direction
	
	if result && result.normal.dot(up_direction) > .5:
		normal = result.normal
	
	var jump_dir = normal.normalized()
	jump_dir.y = min(jump_dir.y, -0.5)
	
	var effective_height := base_jump_height * _calculate_weight(1.0, .7)
	var jump_speed:float = abs(sqrt(2 * effective_height * gravity))
	
	return jump_dir * jump_speed
func apply_gravity(delta, multiplier := 1.0) -> void:
	if is_on_floor():
		return
	
	var gravity_scale := _calculate_weight(1.0, 1.2)
	var max_fall := max_fall_speed * _calculate_weight(0.9, 1.2)
	
	velocity.y = min(velocity.y + gravity * gravity_scale * multiplier * delta, max_fall)
func get_effective_max_speed() -> float:
	var result := 0.0
	
	if is_on_floor():
		result = ground_base_speed * surface.max_speed * _calculate_weight(1.0, 0.75) * speed_multiplier
	else:
		result = air_base_speed * _calculate_weight(1.0, 0.6)
	
	if is_shooting:
		result *= get_shoot_speed_multiplier()
	
	return result
func get_movement_intensity() -> float:
	var max_speed := get_effective_max_speed()
	if max_speed <= 0.01:
		return 0.0
	
	return clamp(abs(velocity.x) / max_speed, 0.0, 1.0)

func apply_impulse(force: Vector2) -> void:
	velocity += force

# --- Ledge System ---

func get_ledge_forward() -> Dictionary:
	var result := {}
	
	var wall_check_origin := global_position + ledge_grab_forward_offset
	var wall_check_target := Vector2(ledge_grab_distance * direction, 0)
	
	var wall_check := _cast_ray(wall_check_origin, wall_check_target)
	
	if wall_check.is_empty():
		return result
	
	GameManager.set_debug_for_drawing(name, "wall_check", {
		"type": "line",
		"origin": wall_check_origin,
		"target": wall_check_origin + wall_check_target,
		"color": Color.GREEN
	})
	
	var wall_probe_origin:Vector2 = wall_check.position - Vector2(0, stand_height)
	var wall_probe_target := Vector2(0, stand_height)
	
	var wall_height_check := _cast_ray(wall_probe_origin, wall_probe_target)
	
	GameManager.set_debug_for_drawing(name, "probe", {
		"type": "line",
		"origin": wall_probe_origin,
		"target": wall_probe_origin + wall_probe_target,
		"color": Color.BLACK
	})
	
	if wall_height_check.is_empty():
		return result
	
	var inward_offset = Vector2(-wall_check.normal.x, wall_check.normal.y-2)
	
	var top_surface_check_origin = wall_height_check.position + inward_offset
	var top_surface_check = _cast_ray(
		top_surface_check_origin,
		Vector2.DOWN * 4
	)
	
	if top_surface_check.is_empty():
		return result
	
	if abs(top_surface_check.normal.y) < 0.9:
		return result
	
	result["position"] = wall_height_check.position
	result["normal"] = wall_check.normal
	
	GameManager.set_debug_for_drawing(name, "ledge_point", {
		"type": "dot",
		"position": result["position"],
		"color": Color.RED
	})
	
	return result
func get_ledge_downward() -> Dictionary:
	var result := {}
	
	var wall_check_target := Vector2(0, ledge_grab_distance)
	var wall_check = _cast_ray(global_position, wall_check_target)
	
	GameManager.set_debug_for_drawing(name, "wall_check", {
		"type": "line",
		"origin": global_position,
		"target": global_position + wall_check_target,
		"color": Color.GREEN
	})
	
	if wall_check.is_empty():
		return result
	
	var wall_probe_origin = wall_check.position + Vector2(crouch_width * direction, 0)
	var wall_probe_target = Vector2(-crouch_width * direction, 0)
	var wall_height_check = _cast_ray(wall_probe_origin, wall_probe_target)
	
	GameManager.set_debug_for_drawing(name, "probe", {
		"type": "line",
		"origin": wall_probe_origin,
		"target": wall_probe_origin + wall_probe_target,
		"color": Color.BLACK
	})
	
	if wall_height_check.is_empty():
		return result
	
	result["position"] = wall_height_check.position
	result["normal"] = wall_height_check.normal
	
	GameManager.set_debug_for_drawing(name, "ledge_point", {
		"type": "dot",
		"position": result.position,
		"color": Color.RED
	})
	
	return result
func get_ledge_info(ledge_position:Vector2, ledge_normal:Vector2) -> Dictionary:
	var offset_dir := ledge_normal.normalized()
	
	var hang_position := Vector2(
		ledge_position.x + (stand_width * 0.5 + safe_margin) * offset_dir.x,
		ledge_position.y + stand_height
	)
	
	var climb_position := Vector2(
		ledge_position.x + (stand_width * 0.5 + safe_margin) * -offset_dir.x,
		ledge_position.y + safe_margin
	)
	
	return {
		"hang_position": hang_position,
		"climb_position": climb_position
	}
func validate_forward_ledge(ledge_position:Vector2, ledge_normal:Vector2) -> bool:
	var offset_dir := ledge_normal.normalized()
	
	var ceiling_check := Vector2(
		ledge_position.x + (crouch_width * 0.5 + 1) * offset_dir.x,
		ledge_position.y - crouch_height * 0.5
	)
	
	GameManager.set_debug_for_drawing(name, "ceiling_detection", {
		"type": "rect",
		"position": ceiling_check,
		"size": Vector2(crouch_width, crouch_height),
		"color": Color.YELLOW
	})
	
	if !can_fit_at(ceiling_check, crouch_collider.shape):
		return false
	
	return _can_grab_ledge(global_position + ledge_grab_forward_offset, ledge_position)
func validate_downward_ledge(ledge_position:Vector2, ledge_normal:Vector2) -> bool:
	var current_shape:Shape2D = current_collider.shape
	var offset_dir := ledge_normal.normalized()
	
	var overlapping_check := Vector2(
		ledge_position.x + (stand_width * 0.5 + 1) * offset_dir.x,
		ledge_position.y + stand_height * 0.5
	)
	
	GameManager.set_debug_for_drawing(name, "overlap_detection", {
		"type": "rect",
		"position": overlapping_check,
		"size": Vector2(stand_width, stand_height),
		"color": Color.BLUE
	})
	
	if !can_fit_at(overlapping_check, current_shape):
		return false
	
	return _can_grab_ledge(global_position, ledge_position)
func can_climb_standing(target_position:Vector2) -> bool:
	var ceiling_check := Vector2(
		target_position.x,
		target_position.y - stand_height * 0.5 - 1
	)
	
	GameManager.set_debug_for_drawing(name, "ceiling_detection", {
		"type": "rect",
		"position": ceiling_check,
		"size": Vector2(stand_width, stand_height),
		"color": Color.BLUE
	})
	
	return can_fit_at(ceiling_check, stand_collider.shape)
func can_climb_crouching(target_position:Vector2) -> bool:
	var ceiling_check := Vector2(
		target_position.x,
		target_position.y - crouch_height * 0.5 - 1
	)
	
	GameManager.set_debug_for_drawing(name, "ceiling_detection", {
		"type": "rect",
		"position": ceiling_check,
		"size": Vector2(crouch_width, crouch_height),
		"color": Color.BLUE
	})
	
	return can_fit_at(ceiling_check, crouch_collider.shape)
func _can_grab_ledge(check_position:Vector2, ledge_position:Vector2) -> bool:
	if ledge_position.distance_to(last_ledge_grabbed) < 2.0:
		return false
	
	return round(check_position.distance_to(ledge_position)) <= ledge_grab_threshold
func _cast_ray(origin:Vector2, target:Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(
		origin,
		origin + target,
		collision_mask,
		[get_rid()]
	)
	
	return GameManager.space_state_ref.intersect_ray(query)

# --- Slope Handling ---

func handle_slopes(delta) -> void:
	if !is_on_floor():
		surface_velocity.x = move_toward(
			surface_velocity.x,
			0.0,
			1200.0 * delta
		)
		return
	
	if is_on_slope():
		var slope_force:float = get_floor_normal().x * surface.slide_force
		var traction_resistance:float = surface.traction
		
		if abs(slope_force) > traction_resistance:
			surface_velocity.x += (
				slope_force
				* _calculate_weight(1.0, 1.6)
				* 20.0 * delta
			)
	else:
		surface_velocity.x = move_toward(surface_velocity.x, 0.0, 60.0 * delta)
	
	if is_on_wall():
		surface_velocity.x = 0
	
	var max_slide_speed := get_effective_max_speed() * 1.2
	
	surface_velocity.x = clamp(
		surface_velocity.x,
		-max_slide_speed,
		max_slide_speed
	)
func is_on_slope() -> bool:
	if !is_on_floor():
		return false
	
	var angle:float = get_floor_angle(up_direction)
	if angle > 0.01:
		return true
	
	return false

# --- Buffers Handling ---

func _handle_jump_buffer(delta:float) -> void:
	jump_buffer = max(jump_buffer - delta, 0.0)
	
	if input.jump_pressed:
		jump_buffer = buffer_jump_time
func _handle_coyote_time(delta:float) -> void:
	coyote_time = max(coyote_time - delta, 0.0)
	
	if is_on_floor():
		coyote_time = buffer_coyote_time_max

# --- Gun Handling ---

func handle_shooting() -> void:
	if input.shoot_pressed:
		gun.request_trigger_press()
	
	elif input.shoot_held:
		gun.request_trigger_hold()
	
	else:
		gun.request_trigger_release()
func get_accuracy() -> float:
	var base_accuracy:float = lerp(1.0, 0.75, get_movement_intensity())
	base_accuracy *= get_stance_stability()
	
	return clamp(base_accuracy, 0.3, 1.0)
func get_stance_stability() -> float:
	match stance:
		Stance.RUN: return 0.7
		Stance.CROUCH: return 1.0
		Stance.AIR: return 0.5
		_: return 0.9
func get_shoot_speed_multiplier() -> float:
	match stance:
		Stance.RUN:
			return 0.85
		Stance.STAND:
			return 0.9
		Stance.CROUCH:
			return 0.95
		_:
			return 1.0

func take_damage(data: DamageData) -> void:
	if state_machine.current_state == "death": return
	
	if data.reaction == DamageData.ReactionTypes.INSTAKILL:
		hp = 0
		state_machine.change_state("dead", {"knockback_vector": velocity})
		return
	
	hp -= data.damage
	
	CameraController.shake(0.2)
	
	var knockback_dir := (data.direction + up_direction).normalized()
	var knockback_magnitude := data.knockback_force * _calculate_weight(1.2, 0.6)
	var knockback_vector := knockback_dir * knockback_magnitude
	var calculated_stun = clamp(knockback_magnitude * 0.001, 0, 1.5)
	
	if hp > 0:
		current_hurtbox.start_iframes(calculated_stun + 0.5)
		state_machine.change_state(
			"hurt",
			{
				"knockback_vector": knockback_vector,
				"stun_time": calculated_stun
			}
		)
		
		return
	
	current_hurtbox.disabled = true
	state_machine.change_state("dead", {
		"knockback_vector": knockback_vector * 1.5
		})

func _calculate_weight(light:float, heavy:float) -> float:
	return lerp(light, heavy, weight_ratio)
