@tool
extends Node2D
class_name LevelSettings

var _debug_draws := {}

@export var world_size:Vector2i :
	set(value):
		world_size = value
		queue_redraw()

var world_bounds:Rect2i

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	
	if Engine.is_editor_hint():
		return
	
	world_bounds = Rect2i(Vector2i(0, 0), world_size)
	
	var bullets_container := Node2D.new()
	bullets_container.name = "Bullets"
	add_child(bullets_container)
	
	GameManager.bullet_pool_refresh(bullets_container)
	GameManager.refresh_current_scene(self)
	
	CameraController.refresh(self)
	CameraController.follow($PlayerSoldier)
	CameraController.snap()
	
	for i in get_children():
		if i is Soldier:
			i.death.connect(on_soldier_death)
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, world_size), Color.YELLOW, false, 4.0)
	
	elif GameManager.debug == GameManager.DebugTypes.VISUAL:
		for i in _debug_draws.values():
			match i.type:
				"line":
					draw_line(i.origin, i.target, i.color)
				
				"dot":
					draw_circle(i.position, 1.0, i.color)
				
				"rect":
					var rect = Rect2(
						(i.position - i.size * 0.5), i.size
					)
					draw_rect(rect, i.color)
func _on_child_entered_tree(node: Node) -> void:
	if Engine.is_editor_hint() && node is Node2D:
		node.show_behind_parent = true

func on_soldier_death(node:Soldier) -> void:
	if node.controller_type == Soldier.ControllerType.PLAYER:
		GameManager.change_to_death_scene()
	
	else:
		node.queue_free()
