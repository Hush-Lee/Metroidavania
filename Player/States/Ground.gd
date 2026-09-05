class_name	PlayerStateGround
extends PlayerState
#region /// Ground state

@onready var idle: PlayerStateIdle = %Idle
@onready var run: PlayerStateRun = %Run
@onready var crouch: PlayerStateCrouch = $Crouch

@onready var current_state:PlayerState 
#endregion

func init()->void:
	idle.player = player
	run.player = player
	crouch.player = player
	pass
	
func enter()->void:
	current_state=null
	switchState()
	pass
	
func exit()->void:
	if current_state:
		current_state.exit()
	current_state = null
	pass

func handle_input(_event:InputEvent)->PlayerState:
	if _event.is_action_pressed("jump"):
		if current_state==crouch:
			# 蹲跳只用于下穿单向平台: 由 Crouch 自行决定(有平台->穿板, 实心地面->不动作)
			return current_state.handle_input(_event)
		player.velocity.y=player.jump_speed
		player.coyote_able = false
		return air
	
	return next_state;

func process(_delta: float) -> PlayerState:
	# 离地判定放回 process(跟随输入帧, 手感更跟手)。
	# 安全前提: Air 落地判定有 velocity.y>=0 门控 -> 起跳不会弹回 Ground,
	# 因此这里不会在起跳后运行, coyote 只会在真正走下平台时被授予。
	if not player.is_on_floor():
		# 只有自然离地(走下平台)才授 coyote; 主动穿板(drop_through)不算
		if player.velocity.y>=0 and not player.drop_through:
			player.coyote_able = true
		return air
	# 站在地面时清除穿板标记
	player.drop_through = false
	switchState()
	current_state.process(_delta)

	return next_state

func physics_process(_delta: float) -> PlayerState:
	current_state.physics_process(_delta)
	return next_state

func changeState(state:PlayerState)->void:
	if state ==  current_state:
		return 
	if current_state != null:
		current_state.exit()
	current_state = state
	player.label.text = current_state.name
	current_state.enter()
func switchState():
	if player.direction.y >0.5:
		changeState(crouch)
	elif player.direction.x !=0:
		changeState(run)
	else:
		changeState(idle)
