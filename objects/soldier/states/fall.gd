extends State

#	Notes:
#1 - No camera offset set so it will keep the one from the previous state

func enter(_parameters={}) -> void:
	host.stance = host.Stance.AIR

func physics_update(delta) -> void:
	host.apply_gravity(delta, 1.2)
	host.update_surface()
	host.handle_movement(delta)
	host.handle_shooting()
	
	var prior_velocity:Vector2 = host.velocity
	
	host.move_and_slide()
	
	if host.coyote_time > 0 && host.jump_buffer > 0:
		state_machine.change_state("jump")
		return
	
	if host.input.crouch && !host.is_crouching():
		host.set_crouching()
	
	if !host.input.crouch && host.is_crouching():
		host.try_stand()
	
	if host.input.direction == host.direction:
		var ledge:Dictionary = host.get_ledge_forward()
		
		if !ledge.is_empty() && host.validate_forward_ledge(ledge.position, ledge.normal):
			var ledge_info:Dictionary = host.get_ledge_info(ledge.position, ledge.normal)
			
			state_machine.change_state("hang", {
				"hang_position": ledge_info.hang_position,
				"climb_position": ledge_info.climb_position,
				"ledge_position": ledge.position,
				"direction": -ledge.normal.x
			})
			return
	
	#This code is meant to transfer the velocity acquired from falling to a slope if you falll on one
	if host.is_on_floor():
		#Grabs the normal (direction away from the floor)
		var floor_normal:Vector2 = host.get_floor_normal()
		
		if prior_velocity.y > 0:
			#slope_dir uses a math trick to find the direction the slope is going to
			var slope_dir := Vector2(floor_normal.y, -floor_normal.x)
			#The dot results in the velocity being transfered to the slope direction, making the soldier slide
			var horizontal_speed:float = prior_velocity.dot(slope_dir)
			
			horizontal_speed = clamp(horizontal_speed, -host.air_base_speed, host.air_base_speed)
			host.velocity = slope_dir * horizontal_speed
		
		if !host.can_stand() || host.input.crouch:
			state_machine.change_state("crouch")
		
		else:
			state_machine.change_state("stand")
