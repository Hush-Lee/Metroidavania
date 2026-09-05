class_name PlayerStateAir
extends PlayerState

#region child state
@onready var rise: PlayerStateRise = %Rise
@onready var fall: PlayerStateFall = %Fall
var current_state:PlayerState 
var coyote_time:float = 0.125
var coyote_timer:float
# buffer_time/buffer_timer 已上收到 player(角色手感参数, 跨状态共享)
#endregion 

func init()->void:
	rise.player = player
	fall.player = player
	pass
	
func enter()->void:
	current_state = null
	if player.coyote_able :
		coyote_timer=coyote_time
	else :
		coyote_timer = 0
	switchState()
	pass
	
func exit()->void:
	# 离开空中状态时退出当前子状态, 与 Ground.exit 对称:
	# Fall.exit 会复位重力倍率, 不退出会导致 1.165 泄漏到地面/上升阶段
	if current_state:
		current_state.exit()
	current_state = null
	pass

func handle_input(_event:InputEvent)->PlayerState:
	if handle_jump(_event):
		return next_state
	current_state.handle_input(_event)
	return next_state

func process(_delta: float) -> PlayerState:
	# 落地判定放回 process(跟随输入帧, 手感更跟手):
	# velocity.y>=0 门控是同步赋值不会滞后, 起跳后即使读到旧 floor 也不会误判落地/回弹
	if player.is_on_floor() and player.velocity.y>=0:
		player.jump_count=0
		# 缓冲跳只在"不打算下蹲"时触发: 若按着下方向(想落地蹲下/穿单向平台),
		# 不在这里抢先起跳, 取消缓冲并交给落地后的 Ground/crouch 决定下穿
		if player.buffer_timer>0:
			# 方案D: 落地缓冲跳 = 落地瞬间"重新按跳"(与普通起跳手感一致, 无帧级歧义):
			# 有缓冲且没按 ↓ 就触发; 触发瞬间若键已松开(短按)则立即按可变跳高规则给矮跳(×0.6),
			# 仍按住则全高起跳、后续松键再截断 —— 短按=矮跳, 长按=可控全高
			if player.direction.y <= 0.5:
				player.velocity.y=player.jump_speed
				player.buffer_timer=0.0
				player.coyote_able = false
				switchState()
				if not Input.is_action_pressed("jump"):
					player.velocity.y *= 0.6
				return next_state
			# 想落地蹲下/穿板: 取消缓冲, 正常落地交给 Ground/crouch
			player.buffer_timer=0.0
		return ground
	switchState()
	current_state.process(_delta)
	return next_state

func physics_process(_delta: float) -> PlayerState:
	coyote_timer = coyote_timer - _delta if coyote_timer>0.0 else 0.0
	player.velocity.x = player.direction.x*player.move_speed
	current_state.physics_process(_delta)
	return next_state
	
func handle_jump(_event:InputEvent)->bool:
	if _event.is_action_pressed("jump"):
		if coyote_timer>0:
			player.velocity.y= player.jump_speed
			coyote_timer=0
		elif player.jump_count<player.air_jump:
			player.velocity.y=player.jump_speed
			player.jump_count+=1
		else:
			player.buffer_timer = player.buffer_time
		player.coyote_able = false
		switchState()
		return true
	if(_event.is_action_released("jump")):
		# 方案D: 松键不再取消缓冲(缓冲资格在落地时点统一结算, 消除事件顺序竞态);
		# 这里仅保留"松键截断当前跳高"的可变跳高行为
		player.velocity.y*=0.6
		return true
	return false
	
func changeState(state:PlayerState):
	if state == current_state:
		return
	if current_state:
		current_state.exit()
	current_state=state
	player.label.text = current_state.name
	current_state.enter()
func switchState():
	if player.velocity.y>=0:
		changeState(fall)
	else:
		changeState(rise)
