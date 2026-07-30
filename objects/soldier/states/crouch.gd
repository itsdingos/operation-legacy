extends State

func enter(_parameters={}) -> void:
	host.stance = host.Stance.CROUCH
	host.last_ledge_grabbed = Vector2.ZERO
	
	host.set_crouching()
	
	host.desired_camera_offset = host.get_lookahead_vector()

func physics_update(delta) -> void:
	if host.is_on_floor():
		host.last_floor_normal = host.get_floor_normal()
	
	host.update_surface()
	host.handle_slopes(delta)
	host.handle_movement(delta)
	host.handle_shooting()
	host.move_and_slide()
	
	if !host.is_on_floor():
		state_machine.change_state("fall")
		return
	
	if host.can_stand():
		if host.jump_buffer > 0:
			state_machine.change_state("jump")
			return
		
		if !host.input.crouch:
			state_machine.change_state("stand")
			return
	
	if host.input.down_pressed:
		var ledge:Dictionary = host.get_ledge_downward()
		
		if !ledge.is_empty() && host.validate_downward_ledge(ledge.position, ledge.normal):
			var ledge_info:Dictionary = host.get_ledge_info(ledge.position, ledge.normal)
			
			state_machine.change_state("hang", {
				"hang_position": ledge_info.hang_position,
				"climb_position": ledge_info.climb_position,
				"ledge_position": ledge.position,
				"direction": -ledge.normal.x
			})
			return
