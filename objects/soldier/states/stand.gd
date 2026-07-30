extends State

func enter(_parameters={}) -> void:
	host.stance = host.Stance.STAND
	host.last_ledge_grabbed = Vector2.ZERO
	
	host.set_standing()
	
	host.desired_camera_offset = host.get_lookahead_vector()

func physics_update(delta) -> void:
	if host.is_on_floor():
		host.last_floor_normal = host.get_floor_normal()
	
	host.update_surface()
	host.handle_slopes(delta)
	
	if host.input.run && host.input.direction != 0 && !host.is_on_wall():
		host.stance = host.Stance.RUN
		host.speed_multiplier = 2
	
	else:
		host.stance = host.Stance.STAND
		host.speed_multiplier = 1.0
	
	host.handle_movement(delta)
	host.handle_shooting()
	host.move_and_slide()
	
	if !host.is_on_floor():
		state_machine.change_state("fall")
		return
	
	if host.jump_buffer > 0:
		state_machine.change_state("jump")
		return
	
	if host.input.crouch:
		state_machine.change_state("crouch")
		return

func exit() -> void:
	host.speed_multiplier = 1.0
	host.accel_multiplier = 1.0
