# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends CanvasLayer
class_name LeaderboardScreen

signal back_pressed

@onready var entries_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/EntriesContainer
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

var current_score: int = -1

func _ready() -> void:
	visible = false
	back_button.pressed.connect(func(): back_pressed.emit())

func show_leaderboard(highlight_score: int = -1) -> void:
	current_score = highlight_score
	populate_entries()
	visible = true

func hide_screen() -> void:
	visible = false

func populate_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()

	var leaderboard = GameState.get_leaderboard()
	if leaderboard.is_empty():
		var label = Label.new()
		label.text = "No scores yet!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entries_container.add_child(label)
		return

	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		var panel = create_entry_panel(i + 1, entry["score"], entry.get("date", ""))
		if entry["score"] == current_score:
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.5, 0.2, 0.5)
			style.set_corner_radius_all(8)
			panel.add_theme_stylebox_override("panel", style)
		entries_container.add_child(panel)

func create_entry_panel(rank: int, score: int, date: String) -> PanelContainer:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	var rank_label = Label.new()
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size.x = 50
	rank_label.add_theme_font_size_override("font_size", 24)
	hbox.add_child(rank_label)

	var score_label = Label.new()
	score_label.text = "%d" % score
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 28)
	hbox.add_child(score_label)

	if date != "":
		var date_label = Label.new()
		date_label.text = date.substr(0, 10) if date.length() > 10 else date
		date_label.add_theme_font_size_override("font_size", 16)
		date_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		hbox.add_child(date_label)

	return panel
