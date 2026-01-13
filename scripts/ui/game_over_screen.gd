# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends CanvasLayer
class_name GameOverScreen

signal play_again_pressed
signal leaderboard_pressed

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var time_bonus_label: Label = $Panel/VBoxContainer/TimeBonusLabel
@onready var final_score_label: Label = $Panel/VBoxContainer/FinalScoreLabel
@onready var play_again_button: Button = $Panel/VBoxContainer/PlayAgainButton
@onready var leaderboard_button: Button = $Panel/VBoxContainer/LeaderboardButton

func _ready() -> void:
	visible = false
	play_again_button.pressed.connect(func(): play_again_pressed.emit())
	leaderboard_button.pressed.connect(func(): leaderboard_pressed.emit())

func show_game_over(won: bool, final_score: int, time_bonus: int = 0) -> void:
	if won:
		title_label.text = "Board Cleared!"
		title_label.add_theme_color_override("font_color", Color.GREEN)
		time_bonus_label.visible = true
		time_bonus_label.text = "Time Bonus: +%d" % time_bonus
		score_label.text = "Base Score: %d" % (final_score - time_bonus)
	else:
		title_label.text = "Game Over"
		title_label.add_theme_color_override("font_color", Color.RED)
		time_bonus_label.visible = false
		score_label.text = "Score: %d" % final_score
	final_score_label.text = "Final Score: %d" % final_score
	visible = true

func hide_screen() -> void:
	visible = false
