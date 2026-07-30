extends State

#	Notes:
#1 - Camera offset set to 0 to avoid the camera from moving around in wall jumps and making the player dizzy

var hang_position := Vector2.ZERO
var climb_position := Vector2.ZERO

func enter(params:={}):
	hang_position = params["hang_position"]
	climb_position = params["climb_position"]
	
	host.velocity = Vector2.ZERO
	host.global_position = hang_position
	host.direction = params["direction"]
	host.last_ledge_grabbed = params["ledge_position"]
	host.set_standing()
	host.reset_physics_interpolation()
	
	host.desired_camera_offset = Vector2.ZERO

func physics_update(_delta) -> void:
	if host.input.jump_pressed:
		if host.input.direction == -host.direction:
			state_machine.change_state("wall_jump", {"direction": -host.direction})
			return
		
		else:
			if host.can_climb_standing(climb_position):
				host.global_position = climb_position
				host.jump_buffer = 0
				host.reset_physics_interpolation()
				
				state_machine.change_state("stand")
				return
			
			elif host.can_climb_crouching(climb_position):
				host.global_position = climb_position
				host.jump_buffer = 0
				host.reset_physics_interpolation()
				
				state_machine.change_state("crouch")
				return
	
	if host.input.down_pressed:
		state_machine.change_state("fall")
		return
