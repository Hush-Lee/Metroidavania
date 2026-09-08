class_name PlayerStateGround
extends PlayerState

#region /// child states
@onready var run: PlayerStateRun = %Run
@onready var idle: PlayerStateIdle = %Idle
@onready var crouch: PlayerStateCrouch = %Crouch
#endregion

var current_state:PlayerState

func init()->void:
	idle.player = player
	run.player = player
	crouch.player = player
	pass

func enter()->void:
	current_state = null
	switchState()
	pass

func exit()->void:
	if current_state:
		current_state.exit()
	current_state = null
	pass

func handle_input(_event:InputEvent)->PlayerState:
	if _event.is_action_pressed("jump"):
		if current_state == crouch:
			# 蹲跳只用于下穿单向平台: 由 Crouch 决定(有平台->穿板, 实心地面->不动作)
			return current_state.handle_input(_event)
		player.velocity.y = player.jump_speed
		player.cayote_able = false
		return air
	if current_state:
		current_state.handle_input(_event)
	return next_state

func process(_delta: float) -> PlayerState:
	# 离地判定: 只有自然离地(走下平台)才授 cayote;
	# 起跳后顶层状态是 Air, 不会经过这里(也不会有多段跳的白送)
	if not player.is_on_floor():
		if player.velocity.y >= 0 and not player.drop_through:
			player.cayote_able = true
		return air
	# drop_through 在 Air 真实落地时清除(不能在这里清: 下穿瞬间的回弹帧也是"在地面")
	switchState()
	if current_state:
		current_state.process(_delta)
	return next_state

func physics_process(_delta: float) -> PlayerState:
	if current_state:
		current_state.physics_process(_delta)
	return next_state

func changeState(state:PlayerState):
	if state and state == current_state:
		return
	if current_state:
		current_state.exit()
	current_state = state
	player.label.text = current_state.name
	current_state.enter()
	pass

func switchState():
	if player.direction.y >= 0.5:
		changeState(crouch)
	elif player.direction.x != 0:
		changeState(run)
	else:
		changeState(idle)
