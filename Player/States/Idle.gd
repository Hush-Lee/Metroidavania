class_name PlayerStateIdle
extends PlayerState

func init()->void:
	pass
	
func enter()->void:
	#player.add_debug_indicator(Color.RED)
	player.animation_player.play("Idle")
	pass
	
func exit()->void:
	pass

func handle_input(_event:InputEvent)->PlayerState:
	return next_state;

func process(_delta: float) -> PlayerState:
	return next_state

func physics_process(_delta: float) -> PlayerState:
	player.velocity.x=0
	return next_state
