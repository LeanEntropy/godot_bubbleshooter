# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends Node

signal score_changed(new_score: int)
signal time_changed(time_left: float)
signal turns_without_match_changed(turns: int)
signal game_over(won: bool, final_score: int)
signal game_started

const LEADERBOARD_FILE = "user://leaderboard.json"
const MAX_LEADERBOARD_ENTRIES = 10

var score: int = 0
var time_left: float = 0.0
var turns_without_match: int = 0
var is_playing: bool = false
var game_won: bool = false
var leaderboard: Array[Dictionary] = []

func _ready() -> void:
	load_leaderboard()

func _process(delta: float) -> void:
	if is_playing:
		time_left -= delta
		time_changed.emit(time_left)
		if time_left <= 0:
			time_left = 0
			end_game(false)

func start_game() -> void:
	score = 0
	time_left = Config.GAME_DURATION
	turns_without_match = 0
	is_playing = true
	game_won = false
	score_changed.emit(score)
	time_changed.emit(time_left)
	turns_without_match_changed.emit(turns_without_match)
	game_started.emit()

func add_score(bubbles_popped: int, dropped_bubbles: int = 0) -> void:
	if bubbles_popped <= 0:
		return
	var points = bubbles_popped * Config.BASE_BUBBLE_SCORE
	if bubbles_popped > Config.MIN_MATCH_COUNT:
		points += (bubbles_popped - Config.MIN_MATCH_COUNT) * Config.COMBO_BONUS_PER_BUBBLE
	points += dropped_bubbles * Config.DROP_BONUS
	score += points
	score_changed.emit(score)

func register_shot(removed_bubbles: bool) -> bool:
	if removed_bubbles:
		turns_without_match = 0
		turns_without_match_changed.emit(turns_without_match)
		return false
	turns_without_match += 1
	turns_without_match_changed.emit(turns_without_match)
	if turns_without_match >= Config.TURNS_UNTIL_NEW_LINE:
		turns_without_match = 0
		turns_without_match_changed.emit(turns_without_match)
		return true
	return false

func board_cleared() -> void:
	score += int(time_left) * Config.TIME_BONUS_MULTIPLIER
	score_changed.emit(score)
	end_game(true)

func end_game(won: bool) -> void:
	is_playing = false
	game_won = won
	add_to_leaderboard(score)
	game_over.emit(won, score)

func get_time_bonus() -> int:
	return int(time_left) * Config.TIME_BONUS_MULTIPLIER

func add_to_leaderboard(new_score: int) -> int:
	var entry = {"score": new_score, "date": Time.get_datetime_string_from_system()}
	leaderboard.append(entry)
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	if leaderboard.size() > MAX_LEADERBOARD_ENTRIES:
		leaderboard.resize(MAX_LEADERBOARD_ENTRIES)
	save_leaderboard()
	for i in range(leaderboard.size()):
		if leaderboard[i]["score"] == new_score and leaderboard[i]["date"] == entry["date"]:
			return i + 1
	return -1

func get_leaderboard() -> Array[Dictionary]:
	return leaderboard

func save_leaderboard() -> void:
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(leaderboard))
		file.close()

func load_leaderboard() -> void:
	if FileAccess.file_exists(LEADERBOARD_FILE):
		var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				leaderboard.assign(json.data)
			file.close()
