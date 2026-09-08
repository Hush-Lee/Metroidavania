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

# 蹲着按跳只用于下穿单向平台(下穿永远从 crouch 状态发起):
# force 检测即时生效(enabled 只限制每帧自动更新), 脚下有平台 -> 下移 4px + drop_through(不授 cayote)进 Air
func handle_input(_event:InputEvent)->PlayerState:
	if _event.is_action_pressed("jump"):
		player.one_way_platform_raycast.force_shapecast_update()
		if player.one_way_platform_raycast.is_colliding():
			player.position.y += 4
			player.drop_through = true
			return air
		player.one_way_platform_raycast.enabled = false
	return next_state

func process(_delta: float) -> PlayerState:
	player.velocity.x -= player.velocity.x * deceleration_rate * _delta
	return next_state

func physics_process(_delta: float) -> PlayerState:
	return next_state
