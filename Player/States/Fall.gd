class_name PlayerStateFall
extends PlayerState
@export var gravity_multiplier:float = 1.165

func init()->void:
	pass

func enter()->void:
	player.gravity_multiplier = gravity_multiplier
	player.animation_player.play("Fall")
	pass

func exit()->void:
	player.gravity_multiplier = 1.0
	pass

func handle_input(_event:InputEvent)->PlayerState:
	return next_state

func process(_delta: float) -> PlayerState:
	return next_state

func physics_process(_delta: float) -> PlayerState:
	return next_state
