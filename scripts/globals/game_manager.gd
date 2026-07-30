extends Node

enum DebugTypes {
	DISABLED,
	VISUAL,
	TYPED
}

const GRAVITY = 1200.0

var debug:DebugTypes = DebugTypes.VISUAL
var current_scene_ref:LevelSettings
var space_state_ref:PhysicsDirectSpaceState2D

var _pool:Dictionary
var _container:Node2D

func change_to_death_scene() -> void:
	get_tree().reload_current_scene.call_deferred()

func refresh_current_scene(scene:LevelSettings) -> void:
	current_scene_ref = scene
	space_state_ref = scene.get_world_2d().direct_space_state

func get_world_bounds() -> Rect2i:
	return current_scene_ref.world_bounds

func bullet_pool_refresh(container:Node2D) -> void:
	_pool.clear()
	_container = container

func get_bullet(scene: PackedScene) -> Bullet:
	var key = scene.resource_path
	var bullet:Bullet
	
	if !_pool.has(key):
		_pool[key] = []
	
	for i in _pool[key]:
		if !i.active:
			bullet = i
			break
	
	if !bullet:
		bullet = scene.instantiate()
		bullet.name = "Bullet_%d" % _pool[key].size()
		_container.add_child(bullet)
		_pool[key].append(bullet)
		
		if debug == DebugTypes.TYPED:
			push_warning("Bullet pool for %s increased to: %s"%[key, _pool[key].size()])
	
	return bullet

func set_debug_for_drawing(caller_name:String, debug_key:String, debug_info:Dictionary) -> void:
	current_scene_ref._debug_draws["%s_%s" %[caller_name, debug_key]] = debug_info
