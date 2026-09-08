class_name PlayerStateAir
extends PlayerState

#region /// child state
@onready var rise: PlayerStateRise = %Rise
@onready var fall: PlayerStateFall = %Fall
#endregion
#region /// local var
@export var cayote_time:float = 0.125
var cayote_timer : float = 0.0
#endregion

var current_state:PlayerState

func init()->void:
	rise.player = player
	fall.player = player
	pass

func enter()->void:
	current_state = null
	# cayote_able 由 Ground 在真正走下平台那一刻置位
	if player.cayote_able:
		cayote_timer = cayote_time
	else:
		cayote_timer = 0.0
	switchState()
	pass

func exit()->void:
	# 离开空中: 退出子状态(Fall.exit 复位重力倍率), 并复位跳跃预算
	if current_state:
		current_state.exit()
	current_state = null
	player.jump_count = 0
	player.cayote_able = false
	pass

func handle_input(_event:InputEvent)->PlayerState:
	if _event.is_action_pressed("jump"):
		if not cayote_jump() and not air_jump():
			# cayote/二段跳都用完 -> 武装落地缓冲(松键不取消, 落地时结算高度)
			player.buffer_timer = player.buffer_time
		player.cayote_able = false
		switchState()
		return next_state
	if _event.is_action_released("jump"):
		# 可变跳高: 早松早矮
		player.velocity.y *= 0.6
		return next_state
	if current_state:
		current_state.handle_input(_event)
	return next_state

func process(_delta: float) -> PlayerState:
	if cayote_timer > 0.0:
		cayote_timer = cayote_timer - _delta if cayote_timer > _delta else 0.0
	# 落地判定: v.y>=0 门控是同步赋值不滞后,
	# 起跳帧即使读到旧 floor(true) 也会因 v.y<0 不会误判落地回弹
	if player.is_on_floor() and player.velocity.y >= 0:
		player.jump_count = 0
		if player.drop_through:
			# 下穿后的"落地": 刚下穿那帧的残留地面不算(直接回 Ground 交给流程),
			# 只有以明显下落速度(v.y>150)真正落到别的平台才结算并清除标记
			if player.velocity.y > 150:
				player.drop_through = false
			return ground
		if player.buffer_timer > 0.0:
			# 想落地蹲下/穿板(按↓) -> 取消缓冲, 交给 Ground/crouch
			if player.direction.y <= 0.5:
				player.velocity.y = player.jump_speed
				player.buffer_timer = 0.0
				player.cayote_able = false
				switchState()
				# 方案D: 触发瞬间键已松开(短按) -> 立即按可变跳高规则给矮跳(x0.6)
				if not Input.is_action_pressed("jump"):
					player.velocity.y *= 0.6
				return next_state
			player.buffer_timer = 0.0
		return ground
	switchState()
	if current_state:
		current_state.process(_delta)
	return next_state

func physics_process(_delta: float) -> PlayerState:
	# 空中水平移动直接由方向控制(与地面跑一致)
	player.velocity.x = player.direction.x * player.move_speed
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
	if player.velocity.y >= 0:
		changeState(fall)
	else:
		changeState(rise)

func cayote_jump()->bool:
	if cayote_timer > 0.0:
		player.velocity.y = player.jump_speed
		cayote_timer = 0.0
		return true
	return false

func air_jump()->bool:
	if player.jump_count < player.air_jump:
		player.velocity.y = player.jump_speed
		player.jump_count += 1
		return true
	return false
