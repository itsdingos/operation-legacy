extends RefCounted
class_name DamageData

enum ReactionTypes {
	NORMAL,
	INSTAKILL
}

var reaction:ReactionTypes
var damage:float
var direction:Vector2
var knockback_force:float

static func create(
	_reaction := ReactionTypes.INSTAKILL,
	_damage := 0.0,
	_direction := Vector2.ZERO,
	_knockback_force := 0
) -> DamageData:
	var data := DamageData.new()
	
	data.damage = _damage
	data.reaction = _reaction
	data.direction = _direction
	data.knockback_force = _knockback_force
	
	return data
