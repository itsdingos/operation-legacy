@tool
extends Node2D
class_name Bullet

@export_range(0.01, 1.0, 0.01) var weight_ratio := 0.01
@export var hitbox:Shape2D
@export_flags_2d_physics var collision_mask

var active := false
var owner_ref:Soldier
var damage_data := DamageData.create(DamageData.ReactionTypes.NORMAL)
var damage := 10.0
var direction := 1
var velocity := Vector2.ZERO
var origin := Vector2.ZERO

func _physics_process(delta):
	if Engine.is_editor_hint():
		queue_redraw()
		return
	
	if !active || !owner_ref:
		return
	
	var motion = velocity * delta
	var query = PhysicsShapeQueryParameters2D.new()
	
	query.shape = hitbox
	query.transform = global_transform
	query.motion = motion
	query.collision_mask = collision_mask
	query.exclude = [owner_ref.current_hurtbox.rid]
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	var result := GameManager.space_state_ref.get_rest_info(query)
	
	if !result.is_empty():
		var collider := instance_from_id(result.collider_id)
		
		#Calculate the motion, will return an array of floats, the index 0 returns a value between 0 and 1
		#the number returned being how much of the motion happened when the collision happened in percentage.
		var fractions := GameManager.space_state_ref.cast_motion(query)
		
		global_position += motion * fractions[0]
		
		if collider is StaticBody2D:
			deactivate()
			return
		
		if collider is Soldier && collider != owner_ref:
			damage_data.damage = damage
			damage_data.direction = motion.round().sign()
			damage_data.knockback_force = 120
			
			collider.take_damage(damage_data)
			deactivate()
			return
	
	global_position += motion
	velocity.y += GameManager.GRAVITY * weight_ratio * delta
	
	if !GameManager.get_world_bounds().has_point(global_position):
		deactivate()
func _draw() -> void:
	if Engine.is_editor_hint() && hitbox:
		hitbox.draw(get_canvas_item(), ProjectSettings.get_setting("debug/shapes/collision/shape_color"))

func activate(new_origin:Vector2, new_direction:Vector2, definition:WeaponDefinition, owner_reference:Soldier) -> void:
	show()
	
	damage =  definition.damage
	origin = new_origin
	global_position = new_origin
	direction = round(new_direction.x)
	velocity = new_direction * definition.speed
	owner_ref = owner_reference
	active = true
	
	if GameManager.debug == GameManager.DebugTypes.TYPED:
		printt(Engine.get_physics_frames(), "activated", self)
	
	reset_physics_interpolation()
func deactivate() -> void:
	active = false
	
	hide()
