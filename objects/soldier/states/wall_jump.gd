extends State

#	Notes:
#1 - No camera offset set so it will keep the one from the previous state
#(in this case, alway will be Vector2.ZERO from hang state)

var lock_timer: float = 0.0
const LOCK_DURATION: float = 0.15

func enter(parameters={}) -> void:
	lock_timer = LOCK_DURATION
	
	host.stance = host.Stance.AIR
	host.direction = -host.direction
	host.velocity = Vector2(
		(host.air_base_speed * 0.8 * parameters["direction"]) * host._calculate_weight(1.1, 0.85),
		host.get_jump_velocity().y * 0.9
	)

func physics_update(delta) -> void:
	host.apply_gravity(delta)
	host.move_and_slide()
	
	if lock_timer > 0:
		lock_timer -= delta
	else:
		host.handle_movement(delta)
	
	if host.velocity.y >= 0:
		state_machine.change_state("fall")
		return
