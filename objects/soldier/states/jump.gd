extends State

#	Notes:
#1 - No camera offset set so it will keep the one from the previous state

var should_lower_jump := true

func enter(_parameters={}) -> void:
	should_lower_jump = true
	
	host.stance = host.Stance.AIR
	host.jump_buffer = 0
	host.velocity.y = 0
	
	var jump_vector:Vector2 = host.get_jump_velocity()
	
	if host.input.crouch:
		jump_vector *= 0.8
	
	host.velocity += jump_vector

func physics_update(delta) -> void:
	if host.input.crouch && !host.is_crouching():
		host.set_crouching()
	
	if !host.input.crouch && host.is_crouching():
		host.try_stand()
	
	host.apply_gravity(delta)
	
	if !host.input.jump_held && should_lower_jump:
		host.velocity.y /= 2
		should_lower_jump = false
	
	host.handle_movement(delta)
	host.handle_shooting()
	host.move_and_slide()
	
	if host.velocity.y >= 0:
		state_machine.change_state("fall")
