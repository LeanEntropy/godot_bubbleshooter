# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends Node2D
class_name Shooter

signal shot_fired(bubble: Bubble, angle: float)

const TRAJECTORY_STEP: float = 5.0
const MAX_TRAJECTORY_LENGTH: float = 2000.0

var left_wall: float
var right_wall: float
var ceiling_y: float

var current_bubble: Bubble = null
var next_bubble: Bubble = null
var bubble_scene: PackedScene
var is_aiming: bool = false
var current_angle: float = PI / 2
var can_shoot: bool = true
var grid: BubbleGrid

@onready var aim_line: Line2D = $AimLine
@onready var current_bubble_pos: Marker2D = $CurrentBubblePos
@onready var next_bubble_pos: Marker2D = $NextBubblePos
@onready var bubble_container: Node2D = $BubbleContainer

func _ready() -> void:
	bubble_scene = preload("res://scenes/bubble.tscn")
	aim_line.visible = false

func setup(bubble_grid: BubbleGrid, _screen_width: float = 720.0) -> void:
	grid = bubble_grid
	left_wall = Config.LEFT_WALL
	right_wall = Config.RIGHT_WALL
	ceiling_y = grid.global_position.y
	grid.active_colors_changed.connect(_on_active_colors_changed)
	prepare_bubbles()

func _on_active_colors_changed(colors: Array[Bubble.BubbleColor]) -> void:
	# Update current bubble if its color is no longer on the board
	if current_bubble != null and current_bubble.bubble_color not in colors:
		current_bubble.set_bubble_color(Bubble.get_random_color_from_set(colors))
	# Update next bubble if its color is no longer on the board
	if next_bubble != null and next_bubble.bubble_color not in colors:
		next_bubble.set_bubble_color(Bubble.get_random_color_from_set(colors))

func prepare_bubbles() -> void:
	if current_bubble == null:
		spawn_current_bubble()
	if next_bubble == null:
		spawn_next_bubble()

func spawn_current_bubble() -> void:
	var colors = grid.get_active_colors() if grid else []
	current_bubble = bubble_scene.instantiate() as Bubble
	bubble_container.add_child(current_bubble)
	current_bubble.position = current_bubble_pos.position
	current_bubble.set_bubble_color(Bubble.get_random_color_from_set(colors) if not colors.is_empty() else Bubble.get_random_color())

func spawn_next_bubble() -> void:
	var colors = grid.get_active_colors() if grid else []
	next_bubble = bubble_scene.instantiate() as Bubble
	bubble_container.add_child(next_bubble)
	next_bubble.position = next_bubble_pos.position
	next_bubble.scale = Vector2(Config.NEXT_BUBBLE_SCALE, Config.NEXT_BUBBLE_SCALE)
	next_bubble.set_bubble_color(Bubble.get_random_color_from_set(colors) if not colors.is_empty() else Bubble.get_random_color())

func _process(_delta: float) -> void:
	if is_aiming and can_shoot:
		update_aim()

func _input(event: InputEvent) -> void:
	if not can_shoot:
		return

	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		swap_bubbles()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var local_pos = to_local(event.global_position)
			if local_pos.length() < Config.LAUNCHER_RADIUS and local_pos.y > -30:
				swap_bubbles()
			else:
				start_aiming()
		elif is_aiming:
			shoot()
	elif event is InputEventMouseMotion and is_aiming:
		update_aim()

	if event.is_action_pressed("ui_accept") and not is_aiming:
		start_aiming()
	elif event.is_action_released("ui_accept") and is_aiming:
		shoot()

func swap_bubbles() -> void:
	if current_bubble == null or next_bubble == null:
		return
	var temp = current_bubble
	current_bubble = next_bubble
	next_bubble = temp

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(current_bubble, "position", current_bubble_pos.position, Config.BUBBLE_SWAP_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(current_bubble, "scale", Vector2.ONE, Config.BUBBLE_SWAP_DURATION)
	tween.tween_property(next_bubble, "position", next_bubble_pos.position, Config.BUBBLE_SWAP_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(next_bubble, "scale", Vector2(Config.NEXT_BUBBLE_SCALE, Config.NEXT_BUBBLE_SCALE), Config.BUBBLE_SWAP_DURATION)

func start_aiming() -> void:
	is_aiming = true
	aim_line.visible = true
	update_aim()

func update_aim() -> void:
	var mouse_pos = get_global_mouse_position()
	var shooter_pos = current_bubble_pos.global_position
	var direction = mouse_pos - shooter_pos
	var min_rad = deg_to_rad(Config.MIN_AIM_ANGLE)
	var max_rad = deg_to_rad(Config.MAX_AIM_ANGLE)
	current_angle = clampf(atan2(-direction.y, direction.x), min_rad, max_rad)

	var trajectory = calculate_trajectory(shooter_pos, current_angle)
	aim_line.clear_points()
	for point in trajectory:
		aim_line.add_point(to_local(point))

func calculate_trajectory(start_pos: Vector2, angle: float) -> Array[Vector2]:
	var points: Array[Vector2] = [start_pos]
	var current_pos = start_pos
	var current_angle = angle
	var total_distance: float = 0.0

	while total_distance < MAX_TRAJECTORY_LENGTH:
		var direction = Vector2(cos(current_angle), -sin(current_angle))
		var next_pos = current_pos + direction * TRAJECTORY_STEP
		total_distance += TRAJECTORY_STEP

		if next_pos.x <= left_wall:
			var t = (left_wall - current_pos.x) / direction.x
			next_pos = current_pos + direction * t
			next_pos.x = left_wall
			points.append(next_pos)
			current_angle = PI - current_angle
			current_pos = next_pos
			continue
		elif next_pos.x >= right_wall:
			var t = (right_wall - current_pos.x) / direction.x
			next_pos = current_pos + direction * t
			next_pos.x = right_wall
			points.append(next_pos)
			current_angle = PI - current_angle
			current_pos = next_pos
			continue

		if next_pos.y <= ceiling_y + Config.BUBBLE_RADIUS:
			var t = (ceiling_y + Config.BUBBLE_RADIUS - current_pos.y) / direction.y
			if t > 0:
				next_pos = current_pos + direction * t
			next_pos.y = ceiling_y + Config.BUBBLE_RADIUS
			points.append(next_pos)
			break

		var local_pos = grid.to_local(next_pos)
		if grid.check_collision(local_pos).x >= 0:
			points.append(next_pos)
			break

		current_pos = next_pos

	if points.size() == 1:
		points.append(start_pos + Vector2(cos(angle), -sin(angle)) * 100)
	return points

func shoot() -> void:
	if current_bubble == null or not can_shoot:
		return
	is_aiming = false
	aim_line.visible = false

	var bubble = current_bubble
	current_bubble = null

	var global_pos = bubble.global_position
	bubble_container.remove_child(bubble)
	get_parent().add_child(bubble)
	bubble.global_position = global_pos
	bubble.shoot(current_angle)

	shot_fired.emit(bubble, current_angle)
	advance_bubbles()

func advance_bubbles() -> void:
	if next_bubble != null:
		current_bubble = next_bubble
		next_bubble = null
		var tween = current_bubble.create_tween()
		tween.tween_property(current_bubble, "position", current_bubble_pos.position, Config.BUBBLE_ADVANCE_DURATION)
		tween.tween_property(current_bubble, "scale", Vector2.ONE, Config.BUBBLE_ADVANCE_DURATION * 0.67)
	spawn_next_bubble()

func set_can_shoot(value: bool) -> void:
	can_shoot = value
	if not can_shoot:
		is_aiming = false
		aim_line.visible = false

func reset() -> void:
	if current_bubble:
		current_bubble.queue_free()
		current_bubble = null
	if next_bubble:
		next_bubble.queue_free()
		next_bubble = null
	prepare_bubbles()
