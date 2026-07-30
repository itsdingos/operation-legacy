extends DummyController
class_name EnemyController

func update_input(_input_ref:InputData) -> void:
	_input_ref.shoot_held = true
