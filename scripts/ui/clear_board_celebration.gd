# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends CanvasLayer

signal celebration_finished

@onready var clear_board_label: Label = $CenterContainer/VBoxContainer/ClearBoardLabel
@onready var bonus_label: Label = $CenterContainer/VBoxContainer/BonusLabel

func _ready() -> void:
	visible = false

func show_celebration(bonus_score: int) -> void:
	bonus_label.text = "+%d" % bonus_score
	visible = true

	clear_board_label.scale = Vector2.ZERO
	bonus_label.scale = Vector2.ZERO
	clear_board_label.modulate.a = 0
	bonus_label.modulate.a = 0

	var tween = create_tween()
	tween.tween_property(clear_board_label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(clear_board_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(clear_board_label, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(bonus_label, "scale", Vector2(1.3, 1.3), 0.25).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(bonus_label, "modulate:a", 1.0, 0.15)
	tween.tween_property(bonus_label, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(1.5)
	tween.tween_callback(_on_celebration_done)

func _on_celebration_done() -> void:
	var container = $CenterContainer
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		visible = false
		container.modulate.a = 1.0
		celebration_finished.emit()
	)

func hide_celebration() -> void:
	visible = false
