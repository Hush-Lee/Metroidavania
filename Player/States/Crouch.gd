class_name PlayerStateCrouch
extends PlayerState
@export var deceleration_rate = 10
func init()->void:
	pass
	
func enter()->void:
	player.animation_player.play("Crouch")
	player.collision_crouch.disabled = false
	player.collision_stand.disabled = true
	pass
	
func exit()->void:
	player.collision_crouch.disabled = true
	player.collision_stand.disabled = false
	player.one_way_platform_raycast.enabled = false
	pass

# 蹲着按跳只用于下穿单向平台: force 检测即时生效(enabled 只影响每帧自动更新)
# 脚下有单向平台 -> 下移 4px 由重力带下去, 标记 drop_through(不授 coyote), 进入 Air;
# 实心地面 -> 不动作(需先站起来再跳)
func handle_input(_event:InputEvent)->PlayerState:
	if _event.is_action_pressed("jump"):
		player.one_way_platform_raycast.force_shapecast_update()
		if player.one_way_platform_raycast.is_colliding():
			player.position.y += 4
			player.drop_through = true
			return air
	return next_state

func process(_delta: float) -> PlayerState:
	# 减速放回 process(跟随渲染帧), 与原版手感一致
	player.velocity.x -= player.velocity.x * deceleration_rate * _delta
	return next_state

func physics_process(_delta: float) -> PlayerState:
	return next_state
