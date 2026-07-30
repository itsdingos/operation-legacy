extends State

var timer := 1.0

func enter(parameters := {}) -> void:
	host.allow_input = false
	host.velocity = parameters["knockback_vector"]
	
	host.desired_camera_offset = Vector2.ZERO

func physics_update(delta) -> void:
	host.apply_gravity(delta)
	
	if host.is_on_floor():
		host.velocity.x = move_toward(
			host.velocity.x,
			0.0, 
			host.ground_base_accel * host.surface.friction * delta
		)
	else:
		host.velocity.x = move_toward(
			host.velocity.x, 
			0.0, 
			host.air_base_accel * delta
		)
		
	host.move_and_slide()
	
	timer -= delta
	
	if timer < 0:
		host.death.emit(host)
