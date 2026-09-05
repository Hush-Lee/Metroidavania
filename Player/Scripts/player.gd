class_name Player
extends CharacterBody2D
const DEBUG_JUMP_INDICATOR = preload("uid://bra7ft1n8i22b")

#region /// on ready variables
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
@onready var collision_stand: CollisionShape2D = $CollisionStand
@onready var one_way_platform_raycast: ShapeCast2D = $OneWayPlatformRaycast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#endregion


#region /// state machine variable
var states:Array[PlayerState]
var current_state :PlayerState:
	get : return states.front()
var previous_state:PlayerState:
	get : return states[1]
#endregion

#region /// stander variables
@export var move_speed : float = 150
@export var jump_speed : float = -300
var direction : Vector2=Vector2.ZERO
var gravity : float = 980
@onready var label : Label = $Label
var air_jump:int = 1
var jump_count:int= 0
var coyote_able = false
# 缓冲跳参数/计时属于角色手感, 放 player 以便跨状态共享
@export var buffer_time :float = 0.2
var buffer_timer :float = 0.0
# 主动穿板(蹲跳下穿单向平台)标记: 该次离地不授予 coyote
var drop_through = false
var gravity_multiplier :float = 1.0
var max_fall_velocity :float = 600
#endregion

func _ready() -> void:
	var texture = sprite.texture
	if texture:
		# 仅仅读取一下图片的尺寸，就会触发引擎的后台加载
		var _size = texture.get_size()
	initialize_state()
	pass

func _process(delta: float) -> void:
	update_direction()
	change_state(current_state.process(delta))
	pass

func _unhandled_input(event: InputEvent) -> void:
	change_state(current_state.handle_input(event))
	pass

func _physics_process(delta: float) -> void:
	velocity.y += gravity*gravity_multiplier*delta
	velocity.y = velocity.y if velocity.y<max_fall_velocity else max_fall_velocity
	# 缓冲跳计时在 player 递减(固定 60Hz, 与状态机无关)
	buffer_timer = buffer_timer - delta if buffer_timer > 0.0 else 0.0
	change_state(current_state.physics_process(delta))
	move_and_slide()
	pass
func initialize_state()->void:
	states = []
	for c in $States.get_children():
		if c is PlayerState:
			states.append(c)
			c.player = self
		pass
	if states.size()==0:
		return
	for state in states:
		state.init()
	change_state(current_state)
	current_state.enter()
	label.text=current_state.name
	pass

func change_state(new_state:PlayerState)->void:
	if new_state == null or new_state==current_state:
		return
	if current_state:
		current_state.exit()
	states.push_front(new_state)
	label.text=current_state.name
	current_state.enter()
	states.resize(3)
	#resize() 的开销只是丢弃后续数据，开销微小到不计，且后续状态可能保留更多，这里不需要优化
	pass

func update_direction()->void:
	#var prev_dirction:Vector2=direction
	var x_axis = Input.get_axis("left","right")
	var y_axis = Input.get_axis("up","down")
	direction = Vector2(x_axis,y_axis)
	if x_axis < 0 :
		sprite.flip_h = true
	if x_axis > 0 :
		sprite.flip_h = false
	pass


func add_debug_indicator(color=Color.RED)->void:
	var d : Node2D = DEBUG_JUMP_INDICATOR.instantiate()
	get_tree().root.add_child(d)
	d.global_position = global_position
	d.modulate = color
	await get_tree().create_timer(3.0).timeout
	d.queue_free()
	pass
