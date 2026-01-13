# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends Area2D
class_name Bubble

signal popped(bubble: Bubble)

enum BubbleColor { RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE }

const COLOR_VALUES: Dictionary = {
	BubbleColor.RED: Color("#FF4444"),
	BubbleColor.BLUE: Color("#4477FF"),
	BubbleColor.GREEN: Color("#44DD44"),
	BubbleColor.YELLOW: Color("#FFDD44"),
	BubbleColor.PURPLE: Color("#DD44DD"),
	BubbleColor.ORANGE: Color("#FF8844"),
}

@export var bubble_color: BubbleColor = BubbleColor.RED

var angle: float = 0.0
var speed: float = 0.0
var is_shooting: bool = false
var is_falling: bool = false
var is_attached: bool = false
var fall_velocity: float = 0.0
var grid_position: Vector2i = Vector2i(-1, -1)

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	update_color()

func _physics_process(delta: float) -> void:
	if is_shooting:
		position += Vector2(cos(angle), -sin(angle)) * speed * delta
	elif is_falling:
		fall_velocity += Config.FALL_ACCELERATION * delta
		position.y += fall_velocity * delta
		position.x += randf_range(-20, 20) * delta
		if position.y > Config.SCREEN_HEIGHT + 100:
			queue_free()

func set_bubble_color(color: BubbleColor) -> void:
	bubble_color = color
	update_color()

func update_color() -> void:
	if sprite:
		sprite.modulate = COLOR_VALUES[bubble_color]

func shoot(shoot_angle: float) -> void:
	angle = shoot_angle
	speed = Config.SHOOT_SPEED
	is_shooting = true
	is_attached = false
	is_falling = false

func reflect_horizontal() -> void:
	angle = PI - angle

func stop() -> void:
	is_shooting = false
	is_falling = false
	speed = 0.0
	fall_velocity = 0.0

func attach() -> void:
	stop()
	is_attached = true

func start_falling() -> void:
	is_attached = false
	is_shooting = false
	is_falling = true
	fall_velocity = 0.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), Config.FALL_SQUASH_DURATION)
	tween.tween_property(self, "scale", Vector2.ONE, Config.FALL_SQUASH_DURATION)

func pop() -> void:
	is_attached = false
	is_shooting = false
	is_falling = false
	popped.emit(self)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), Config.POP_ANIMATION_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, Config.POP_ANIMATION_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

static func get_random_color() -> BubbleColor:
	return BubbleColor.values()[randi() % BubbleColor.size()]

static func get_random_color_from_set(colors: Array[Bubble.BubbleColor]) -> BubbleColor:
	if colors.is_empty():
		return get_random_color()
	return colors[randi() % colors.size()]
