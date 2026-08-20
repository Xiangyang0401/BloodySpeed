extends Node2D
## 《血红》第一区域「长暖乡」关卡生成
## 教学节奏（从左到右）：移动 → 一段跳 → 二段跳 → 一跃涧（综合应用）
## 一跃涧是文档里的首尾闭环点：开场用二段跳一跃而过（毫无难度）


const GROUND_COLOR := Color(0.05, 0.05, 0.08, 1)
const PLATFORM_COLOR := Color(0.07, 0.07, 0.10, 1)
const GOAL_COLOR := Color(0.9, 0.72, 0.28, 0.9)  # 终点暖色光柱


func _ready() -> void:
	# 1. 出生平地（教学：左右移动）
	_add_block(-200.0, 820.0, 300.0, 60.0)

	# 2. 平台一（教学：一段跳，高 60px，一段跳约 84px 能上）
	_add_block(520.0, 620.0, 240.0, 30.0)

	# 3. 平台二（教学：二段跳，高 120px，需二段跳才能上）
	_add_block(680.0, 780.0, 180.0, 30.0)

	# 4. 一跃涧：x 820~1080 留空 = 断裂口（宽 260px）
	#    一段跳约跨 180px 过不去，二段跳约跨 390px 轻松过

	# 5. 对岸平地（跃涧后的收尾）
	_add_block(1080.0, 1750.0, 300.0, 60.0)

	# 6. 终点标记（暖色光柱，暂作第一区域出口）
	_add_goal(1700.0, 300.0)


func _add_block(x_from: float, x_to: float, top_y: float, thickness: float) -> void:
	# 生成一块实心平台：顶面在 top_y，横向范围 x_from~x_to，厚度 thickness
	var w := x_to - x_from
	var center := Vector2((x_from + x_to) / 2.0, top_y + thickness / 2.0)

	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 1

	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, thickness)
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)

	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-w / 2.0, -thickness / 2.0),
		Vector2(w / 2.0, -thickness / 2.0),
		Vector2(w / 2.0, thickness / 2.0),
		Vector2(-w / 2.0, thickness / 2.0),
	])
	vis.color = GROUND_COLOR
	body.add_child(vis)

	add_child(body)


func _add_goal(x: float, top_y: float) -> void:
	# 终点标记：一根从地面向上延伸的暖色光柱
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-10.0, -160.0),
		Vector2(10.0, -160.0),
		Vector2(10.0, 0.0),
		Vector2(-10.0, 0.0),
	])
	vis.color = GOAL_COLOR
	vis.position = Vector2(x, top_y)
	add_child(vis)
