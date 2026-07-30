@tool
extends Node2D
class_name Hurtbox

@export var disabled: bool = false:
	set(value):
		disabled = value
		_update_physics_layer()
@export var owner_ref: Node2D
@export var shape:Shape2D
@export var debug_color:Color = Color(255, 0, 0, 0.25)
@export_flags_2d_physics var collision_layer: int = 4:
	set(value):
		collision_layer = value
		_update_physics_layer()

var rid: RID
var remaining_iframes: float = 0

func _ready() -> void:
	rid = PhysicsServer2D.area_create()
	
	PhysicsServer2D.area_set_space(rid, get_world_2d().space)
	if shape: PhysicsServer2D.area_add_shape(rid, shape.get_rid())
	PhysicsServer2D.area_set_transform(rid, global_transform)
	PhysicsServer2D.area_set_collision_mask(rid, 0)
	PhysicsServer2D.area_attach_object_instance_id(rid, owner_ref.get_instance_id())
	
	_update_physics_layer()

func _draw() -> void:
	if Engine.is_editor_hint() && shape:
		shape.draw(get_canvas_item(), debug_color)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	
	PhysicsServer2D.area_set_transform(rid, global_transform)
	
	if disabled: return
	
	if remaining_iframes > 0:
		remaining_iframes -= delta
		
		if remaining_iframes <= 0:
			PhysicsServer2D.area_set_collision_layer(rid, collision_layer)

func _exit_tree() -> void:
	if Engine.is_editor_hint(): return
	
	if rid.is_valid():
		PhysicsServer2D.free_rid(rid)

func _update_physics_layer() -> void:
	if !rid.is_valid(): return
	
	if !disabled && remaining_iframes <= 0:
		PhysicsServer2D.area_set_collision_layer(rid, collision_layer)
	else:
		PhysicsServer2D.area_set_collision_layer(rid, 0)

func start_iframes(duration:float) -> void:
	remaining_iframes = duration
	PhysicsServer2D.area_set_collision_layer(rid, 0)
