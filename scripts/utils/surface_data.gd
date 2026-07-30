extends Resource
class_name SurfaceData

@export_category("Surface Details")
@export var friction := 1.0
@export var acceleration := 1.0
@export var max_speed := 1.0
@export var traction := 1.0
@export var slide_force := 1.0

@export_category("Sounds and Animation")
@export var footsteps_sounds: AudioStream
@export var animation_suffix: String
