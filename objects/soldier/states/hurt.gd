extends State

#	Notes:
#1 - No camera offset set so it will keep the one from the previous state

enum HurtPhase { FLYING, GROUNDED, GETTING_UP }
var current_phase: HurtPhase = HurtPhase.FLYING

var stun_duration: float = 0.0

func enter(parameters := {}) -> void:
	host.allow_input = false
	host.velocity = parameters["knockback_vector"]
	
	current_phase = HurtPhase.FLYING
	stun_duration = parameters["stun_time"]

func physics_update(delta: float) -> void:
	host.apply_gravity(delta)
	host.move_and_slide()
	
	match current_phase:
		HurtPhase.FLYING:
			host.velocity.x = move_toward(host.velocity.x, 0.0, host.air_base_accel * delta)
			
			if host.is_on_floor():
				current_phase = HurtPhase.GROUNDED
		
		HurtPhase.GROUNDED:
			host.velocity.x = move_toward(host.velocity.x, 0.0, host.ground_base_accel * host.surface.friction * delta)
			
			stun_duration -= delta
			if stun_duration <= 0:
				if state_machine.previous_state == "crouch":
					state_machine.change_state("crouch")
					return
				state_machine.change_state("stand")
	

func exit() -> void:
	host.allow_input = true
