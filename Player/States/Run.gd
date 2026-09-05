class_name  PlayerStateRun
extends PlayerState
func init()->void:
	pass
	
func enter()->void:
	player.animation_player.play("Run")
	pass
	
func exit()->void:
	pass

func handle_input(_event:InputEvent)->PlayerState:
	return next_state;

func process(_delta: float) -> PlayerState:
	return next_state

func physics_process(_delta: float) -> PlayerState:
	player.velocity.x=player.direction.x * player.move_speed
	return next_state
