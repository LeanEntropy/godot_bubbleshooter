# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends CanvasLayer
class_name HUD

@onready var time_value: Label = $TopBar/TimeSection/TimeValue
@onready var score_value: Label = $TopBar/ScoreSection/ScoreValue
@onready var hearts_container: HBoxContainer = $TopBar/ShotsSection/HeartsContainer

var heart_labels: Array[Label] = []
const HEART_FULL_COLOR = Color(1, 0.4, 0.5, 1)
const HEART_EMPTY_COLOR = Color(0.4, 0.3, 0.4, 0.5)

func _ready() -> void:
	for child in hearts_container.get_children():
		if child is Label:
			heart_labels.append(child)

	GameState.score_changed.connect(_on_score_changed)
	GameState.time_changed.connect(_on_time_changed)
	GameState.turns_without_match_changed.connect(_on_turns_changed)

	_on_score_changed(0)
	_on_time_changed(Config.GAME_DURATION)
	_on_turns_changed(0)

func _on_score_changed(new_score: int) -> void:
	score_value.text = str(new_score)
	var tween = score_value.create_tween()
	tween.tween_property(score_value, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_value, "scale", Vector2.ONE, 0.1)

func _on_time_changed(time_left: float) -> void:
	time_value.text = "%02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	if time_left <= 30:
		time_value.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	else:
		time_value.remove_theme_color_override("font_color")

func _on_turns_changed(turns: int) -> void:
	var remaining = Config.TURNS_UNTIL_NEW_LINE - turns
	for i in range(heart_labels.size()):
		var color = HEART_FULL_COLOR if i < remaining else HEART_EMPTY_COLOR
		heart_labels[i].add_theme_color_override("font_color", color)
		if i == remaining:
			var tween = heart_labels[i].create_tween()
			tween.tween_property(heart_labels[i], "scale", Vector2(1.3, 1.3), 0.1)
			tween.tween_property(heart_labels[i], "scale", Vector2.ONE, 0.1)
