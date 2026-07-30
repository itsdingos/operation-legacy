extends Node
class_name StateMachine

signal state_changed(current_name:StringName, old_state:StringName)
signal machine_reseted()

@export var initial_state:State :
	set(value):
		if value == null:
			push_error("Initial State cannot be of value null.")
			return
		
		if !get_children().has(value):
			push_error("The initial state: '%s' is not a child of the State Machine: '%s:%s'." %[value.name, host.name, name])
			return
		
		initial_state = value

@export_category("Debug")
@export var debug := false :
	set(value):
		if debug == value:
			return
		
		debug = value
		if is_instance_valid(debug_label):
			debug_label.visible = value
@export var debug_label:Label

@onready var current_state:StringName
@onready var previous_state:StringName
@onready var host := get_owner()

var _machine_safely_initialized:bool = false
var states:Dictionary[StringName, State] = {}

func _ready() -> void:
	if !initial_state:
		push_error("The initial state for State Machine: '%s:%s' has not been set." %[host.name, name])
		return
	
	if !get_children().has(initial_state):
		push_error("The initial state: '%s' is not a child of the State Machine: '%s:%s'." %[initial_state.name, host.name, name])
		return
	
	if is_instance_valid(debug_label):
		debug_label.visible = debug
	
	await host.ready
	
	for i in get_children():
		if i is State:
			states[i.name.to_lower()] = i
			i.state_machine = self
			i.host = host
	
	if !states.is_empty():
		current_state = initial_state.name.to_lower()
		_machine_safely_initialized = true
		states[current_state].enter()

func _ensure_initialization() -> bool:
	if !_machine_safely_initialized:
		push_error("State Machine: '%s:%s' has not initialized properly." %[host.name, name])
		return false
	
	return true

func process_update(delta:float) -> void:
	if !_ensure_initialization(): return
	
	if current_state.is_empty(): return
	
	get_current_state().process_update(delta)

func physics_update(delta:float) -> void:
	if !_ensure_initialization(): return
	
	if current_state.is_empty(): return
	
	get_current_state().physics_update(delta)

func change_state(new_state:StringName, parameters:={}) -> void:
	if !_ensure_initialization(): return
	
	if current_state == new_state:
		push_warning("State '%s' is already running in State Machine: '%s:%s'." %[new_state, host.name, name])
		return
	
	if !states.has(new_state):
		push_error("State '%s' not found in State Machine: '%s:%s'." %[new_state, host.name, name])
		return
	
	states[current_state].exit()
	states[new_state].enter(parameters)
	
	previous_state = current_state
	current_state = new_state
	
	state_changed.emit(current_state, previous_state)
	
	if debug && is_instance_valid(debug_label):
		debug_label.text = current_state

func get_current_state() -> State:
	if !_ensure_initialization(): return
	
	return states.get(current_state)

func get_previous_state() -> State:
	if !_ensure_initialization(): return
	
	return states.get(previous_state)

func get_state(state:StringName) -> State:
	if !_ensure_initialization(): return
	
	if !states.has(state):
		push_error("State '%s' not found in State Machine: '%s:%s'." %[state, host.name, name])
		return
	
	return states[state]

func reset() -> void:
	if !_ensure_initialization(): return
	
	if states.has(current_state):
		states[current_state].exit()
	
	current_state = ""
	machine_reseted.emit()
	change_state(initial_state.name.to_lower())
