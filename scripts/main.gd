# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends Node2D

@onready var bubble_grid: BubbleGrid = $BubbleGrid
@onready var shooter: Shooter = $Shooter
@onready var hud: HUD = $HUD
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var leaderboard_screen: LeaderboardScreen = $LeaderboardScreen
@onready var clear_board_celebration = $ClearBoardCelebration
@onready var score_popup_container: Node2D = $ScorePopupContainer

var score_popup_scene: PackedScene
var flying_bubble: Bubble = null
var game_active: bool = false

func _ready() -> void:
	randomize()
	score_popup_scene = preload("res://scenes/score_popup.tscn")

	shooter.shot_fired.connect(_on_shot_fired)
	bubble_grid.bubbles_popped.connect(_on_bubbles_popped)
	bubble_grid.bubble_landed.connect(_on_bubble_landed)
	bubble_grid.board_cleared.connect(_on_board_cleared)
	bubble_grid.danger_line_reached.connect(_on_danger_line_reached)
	game_over_screen.play_again_pressed.connect(_on_play_again)
	game_over_screen.leaderboard_pressed.connect(_on_show_leaderboard)
	leaderboard_screen.back_pressed.connect(_on_leaderboard_back)
	clear_board_celebration.celebration_finished.connect(_on_celebration_finished)
	GameState.game_over.connect(_on_game_over)

	shooter.setup(bubble_grid, Config.SCREEN_WIDTH)
	start_game()

func start_game() -> void:
	bubble_grid.reset()
	shooter.reset()
	game_over_screen.hide_screen()
	leaderboard_screen.hide_screen()
	shooter.set_can_shoot(true)
	game_active = true
	GameState.start_game()

func _on_shot_fired(bubble: Bubble, _angle: float) -> void:
	flying_bubble = bubble
	shooter.set_can_shoot(false)

func _physics_process(_delta: float) -> void:
	if flying_bubble == null or not is_instance_valid(flying_bubble) or not flying_bubble.is_shooting:
		return

	var bubble_local_pos = bubble_grid.to_local(flying_bubble.global_position)
	check_wall_collision(flying_bubble)

	if bubble_grid.check_ceiling_collision(bubble_local_pos):
		land_bubble(bubble_local_pos)
		return

	if bubble_grid.check_collision(bubble_local_pos).x >= 0:
		land_bubble(bubble_local_pos)

func check_wall_collision(bubble: Bubble) -> void:
	if bubble.global_position.x <= Config.LEFT_WALL:
		bubble.global_position.x = Config.LEFT_WALL
		bubble.reflect_horizontal()
	elif bubble.global_position.x >= Config.RIGHT_WALL:
		bubble.global_position.x = Config.RIGHT_WALL
		bubble.reflect_horizontal()

func land_bubble(local_pos: Vector2) -> void:
	if flying_bubble == null:
		return

	var bubble = flying_bubble
	flying_bubble = null

	bubble.get_parent().remove_child(bubble)
	bubble_grid.add_child(bubble)
	bubble.position = local_pos

	if bubble_grid.place_bubble(bubble, local_pos):
		bubble_grid.process_bubble_placement(bubble)
	else:
		bubble.queue_free()
		shooter.set_can_shoot(true)

func _on_bubbles_popped(count: int, dropped: int, pop_positions: Array[Vector2], drop_positions: Array[Vector2]) -> void:
	GameState.add_score(count, dropped)
	GameState.register_shot(true)
	shooter.set_can_shoot(true)

	for i in range(pop_positions.size()):
		var score = Config.BASE_BUBBLE_SCORE if i < Config.MIN_MATCH_COUNT else Config.COMBO_BONUS_PER_BUBBLE
		spawn_score_popup(pop_positions[i], score, Color(1, 1, 0.5))
		await get_tree().create_timer(0.05).timeout

	for pos in drop_positions:
		spawn_score_popup(pos, Config.DROP_BONUS, Color(0.5, 1, 0.5))
		await get_tree().create_timer(0.05).timeout

func spawn_score_popup(pos: Vector2, score: int, color: Color) -> void:
	var popup = score_popup_scene.instantiate()
	score_popup_container.add_child(popup)
	popup.global_position = pos
	popup.setup(score, color)

func _on_bubble_landed() -> void:
	if GameState.register_shot(false):
		bubble_grid.add_row_at_top()
	shooter.set_can_shoot(true)

func _on_board_cleared() -> void:
	game_active = false
	shooter.set_can_shoot(false)
	clear_board_celebration.show_celebration(GameState.get_time_bonus())

func _on_celebration_finished() -> void:
	GameState.board_cleared()

func _on_danger_line_reached() -> void:
	game_active = false
	shooter.set_can_shoot(false)
	GameState.end_game(false)

func _on_game_over(won: bool, final_score: int) -> void:
	shooter.set_can_shoot(false)
	game_over_screen.show_game_over(won, final_score, GameState.get_time_bonus() if won else 0)

func _on_play_again() -> void:
	start_game()

func _on_show_leaderboard() -> void:
	game_over_screen.hide_screen()
	leaderboard_screen.show_leaderboard(GameState.score)

func _on_leaderboard_back() -> void:
	leaderboard_screen.hide_screen()
	game_over_screen.visible = true
