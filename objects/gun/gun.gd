extends Node2D
class_name Gun

@export var definition:WeaponDefinition
@export var bullet_scene:PackedScene

var owner_ref:Soldier = null
var cooldown := 0.0

func _physics_process(delta: float) -> void:
	cooldown = max(cooldown - delta, 0.0)
	scale.x = sign(owner_ref.direction)
	
	queue_redraw()

# --- Requests ---

func request_trigger_hold() -> void:
	if definition.fire_mode == definition.FireMode.AUTO:
		try_shoot()
func request_trigger_press() -> void:
	if definition.fire_mode == definition.FireMode.SEMI:
		try_shoot()
func request_trigger_release() -> void:
	pass

# --- Shooting Handling ---
func try_shoot() -> void:
	if cooldown > 0:
		return
	
	_shoot()
	
	cooldown = definition.fire_rate
func _shoot() -> void:
	if owner_ref == null:
		return
	
	var accuracy:float = owner_ref.get_accuracy()
	
	var base_dir := Vector2(owner_ref.direction, 0)
	
	var max_spread := deg_to_rad(definition.max_spread_degrees)
	var spread := (1.0 - accuracy) * max_spread
	var angle_offset := randf_range(-spread, spread)
	
	var dir := base_dir.rotated(angle_offset).normalized()
	
	var bullet_instance = GameManager.get_bullet(bullet_scene)
	bullet_instance.activate($Muzzle.global_position, dir, definition, owner_ref)
