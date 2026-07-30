extends DummyController
class_name PlayerController

func update_input(input_ref:InputData) -> void:
	input_ref.direction = round(Input.get_axis("left", "right"))
	input_ref.jump_pressed = Input.is_action_just_pressed("jump")
	input_ref.jump_held = Input.is_action_pressed("jump")
	input_ref.crouch = Input.is_action_pressed("crouch")
	input_ref.up = Input.is_action_pressed("up")
	input_ref.down_pressed = Input.is_action_just_pressed("down")
	input_ref.down_held = Input.is_action_pressed("down")
	input_ref.run = Input.is_action_pressed("run")
	input_ref.shoot_pressed = Input.is_action_just_pressed("shoot")
	input_ref.shoot_held = Input.is_action_pressed("shoot")
