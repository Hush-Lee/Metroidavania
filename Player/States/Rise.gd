class_name PlayerStateRise
extends PlayerState

func init()->void:
	pass

func enter()->void:
	player.animation_player.play("Rise")
	player.animation_player.pause()
	pass

func exit()->void:
	pass

func handle_input(_event:InputEvent)->PlayerState:
	return next_state

func process(_delta: float) -> PlayerState:
	# 上升动画帧跟随速度推进
	set_rise_frame()
	return next_state

func physics_process(_delta: float) -> PlayerState:
	return next_state

func set_rise_frame():
	var frame : float = remap(player.velocity.y, player.jump_speed, 0.0, 0.0, 0.5)
	player.animation_player.seek(frame, true)
	pass
