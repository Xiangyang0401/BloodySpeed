extends CharacterBody2D
## 《血红》玩家控制器原型
## 年轻形态三技能：二段跳(空格) + 冲刺(Shift) + 切割(F)
## 切割变体：空中按 F = 垂直向下下落攻击
## 成熟形态：滑翔替代二段跳（洞察/安抚暂未实现，冲刺/切割暂时保留）
## 调试：按 T 切换 年轻/成熟 形态（白色=年轻，黑色=成熟）


@export var speed: float = 240.0

# 跳跃参数（三段独立）
@export var jump_velocity_young_first: float = -450.0   # 年轻·一段跳（约 84px 高）
@export var jump_velocity_young_second: float = -530.0  # 年轻·二段跳（约 117px 高）
@export var jump_velocity_mature: float = -600.0        # 成熟·跳跃（约 150px 高）

@export var gravity: float = 1200.0
@export var max_fall_speed: float = 640.0
@export var glide_fall_speed: float = 140.0

# 冲刺参数
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

# 切割参数
@export var cut_cooldown: float = 0.4
@export var slash_duration: float = 0.12
@export var down_slash_velocity: float = 800.0  # 下落攻击的下坠速度（向下为正）


# 能力状态（年轻形态默认）
var has_double_jump: bool = true
var has_glide: bool = false

var _jumps_left: int = 2
var _facing: int = 1  # 1=右 -1=左

# 冲刺/切割运行时状态
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _slash_time_left: float = 0.0
var _cut_cooldown_left: float = 0.0
var _is_down_slashing: bool = false

@onready var _visual: Polygon2D = $Visual
@onready var _slash: Polygon2D = $Slash
@onready var _slash_down: Polygon2D = $SlashDown
@onready var _form_label: Label = $CanvasLayer/FormLabel
@onready var _skill_label: Label = $CanvasLayer/SkillLabel


func _ready() -> void:
	_setup_font()
	_set_form(true)  # 初始年轻形态（白色）


func _setup_font() -> void:
	# 用系统中文字体，避免中文显示为方块
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "sans-serif"])
	_form_label.add_theme_font_override("font", font)
	_skill_label.add_theme_font_override("font", font)


func _physics_process(delta: float) -> void:
	# 冷却倒计时
	_dash_cooldown_left = max(0.0, _dash_cooldown_left - delta)
	_cut_cooldown_left = max(0.0, _cut_cooldown_left - delta)

	# 水平移动：冲刺锁速 / 下落攻击锁水平 / 正常
	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity.x = dash_speed * _facing
		_visual.scale.x = 1.4
	elif _is_down_slashing:
		velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
		_visual.scale.x = 1.0
	else:
		_visual.scale.x = 1.0
		var direction := Input.get_axis("ui_left", "ui_right")
		if Input.is_physical_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_physical_key_pressed(KEY_D):
			direction += 1.0
		direction = clamp(direction, -1.0, 1.0)
		if direction != 0.0:
			velocity.x = direction * speed
			_facing = 1 if direction > 0.0 else -1
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)

	# 落地重置跳跃次数
	if is_on_floor():
		_jumps_left = 2 if has_double_jump else 1

	# 跳跃（含二段跳，分段独立初速）
	if Input.is_action_just_pressed("ui_accept") and _jumps_left > 0:
		if has_double_jump:
			velocity.y = jump_velocity_young_first if _jumps_left == 2 else jump_velocity_young_second
		else:
			velocity.y = jump_velocity_mature
		_jumps_left -= 1

	# 垂直速度：下落攻击 > 滑翔 > 普通重力
	var gliding: bool = has_glide and not is_on_floor() \
		and Input.is_action_pressed("ui_accept") and velocity.y > 0.0

	if _is_down_slashing:
		velocity.y = down_slash_velocity  # 匀速高速下坠
	elif gliding:
		velocity.y = move_toward(velocity.y, glide_fall_speed, gravity * 2.0 * delta)
	else:
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

	move_and_slide()

	# 地面刀光计时
	if _slash_time_left > 0.0:
		_slash_time_left -= delta
		if _slash_time_left <= 0.0:
			_slash.visible = false

	# 下落攻击：落地后结束
	if _is_down_slashing and is_on_floor():
		_is_down_slashing = false
		_slash_down.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			_set_form(not has_double_jump)
		elif event.keycode == KEY_SHIFT:
			_try_dash()
		elif event.keycode == KEY_F:
			_try_cut()


func _try_dash() -> void:
	if _dash_cooldown_left > 0.0:
		return
	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown


func _try_cut() -> void:
	if _cut_cooldown_left > 0.0:
		return
	_cut_cooldown_left = cut_cooldown
	if is_on_floor():
		# 地面：水平刀光，朝朝向
		_slash_time_left = slash_duration
		_slash.scale.x = _facing
		_slash.visible = true
	else:
		# 空中：垂直向下下落攻击
		_is_down_slashing = true
		_slash_down.visible = true


func _set_form(young: bool) -> void:
	has_double_jump = young
	has_glide = not young
	var max_jumps := 2 if young else 1
	_jumps_left = min(_jumps_left, max_jumps)
	if young:
		_visual.color = Color.WHITE
		_form_label.text = "形态：年轻  [T 切换]"
		_skill_label.text = "[空格] 二段跳    [Shift] 冲刺    [F] 切割/下落"
	else:
		_visual.color = Color.BLACK
		_form_label.text = "形态：成熟  [T 切换]"
		_skill_label.text = "[空格] 滑翔    [Shift] 冲刺    [F] 切割/下落"
