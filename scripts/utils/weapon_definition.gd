extends Resource
class_name WeaponDefinition

enum FireMode {
	AUTO,
	SEMI
}

@export_group("Gun Related Settings")
@export var fire_mode:FireMode
@export var fire_rate := 0.15
@export var max_spread_degrees := 15.0
@export var max_range:int = 200

@export_group("Bullet Related Settings")
@export var damage:int = 20
@export var speed:int = 180
