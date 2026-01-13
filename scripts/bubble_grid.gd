# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends Node2D
class_name BubbleGrid

signal bubbles_popped(count: int, dropped: int, pop_positions: Array[Vector2], drop_positions: Array[Vector2])
signal bubble_landed
signal board_cleared
signal danger_line_reached
signal active_colors_changed(colors: Array[Bubble.BubbleColor])

# Neighbor offsets for non-offset rows (11 bubbles)
const NEIGHBORS_EVEN: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1),
]
# Neighbor offsets for offset rows (10 bubbles)
const NEIGHBORS_ODD: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]

var grid: Array = []
var bubble_scene: PackedScene
var active_colors: Array[Bubble.BubbleColor] = []
var row_offset: int = 0

func _ready() -> void:
	bubble_scene = preload("res://scenes/bubble.tscn")
	initialize_grid()

func initialize_grid() -> void:
	grid.clear()
	row_offset = 0
	for row in range(Config.GRID_ROWS):
		var row_array: Array = []
		row_array.resize(Config.GRID_COLUMNS)  # Max columns, some will be unused
		row_array.fill(null)
		grid.append(row_array)
	generate_initial_bubbles()
	update_active_colors()

func generate_initial_bubbles() -> void:
	for row in range(Config.INITIAL_ROWS):
		for col in range(get_row_columns(row)):
			var bubble = create_bubble_at(col, row)
			if bubble:
				bubble.set_bubble_color(Bubble.get_random_color())

func create_bubble_at(col: int, row: int) -> Bubble:
	if not is_valid_position(col, row):
		return null
	var bubble = bubble_scene.instantiate() as Bubble
	add_child(bubble)
	bubble.position = grid_to_world(col, row)
	bubble.grid_position = Vector2i(col, row)
	bubble.is_attached = true
	grid[row][col] = bubble
	return bubble

func is_row_offset(row: int) -> bool:
	return (row + row_offset) % 2 == 1

func get_row_columns(row: int) -> int:
	# Offset rows have one fewer bubble (10 vs 11)
	return Config.GRID_COLUMNS - 1 if is_row_offset(row) else Config.GRID_COLUMNS

func grid_to_world(col: int, row: int) -> Vector2:
	var x = col * Config.TILE_WIDTH + Config.TILE_WIDTH / 2.0
	if is_row_offset(row):
		x += Config.ROW_OFFSET_PX
	return Vector2(x, row * Config.TILE_HEIGHT + Config.TILE_WIDTH / 2.0)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var row = clampi(int(round((world_pos.y - Config.TILE_WIDTH / 2.0) / Config.TILE_HEIGHT)), 0, Config.GRID_ROWS - 1)
	var x_offset = Config.ROW_OFFSET_PX if is_row_offset(row) else 0.0
	var col = clampi(int(round((world_pos.x - Config.TILE_WIDTH / 2.0 - x_offset) / Config.TILE_WIDTH)), 0, get_row_columns(row) - 1)
	return Vector2i(col, row)

func is_valid_position(col: int, row: int) -> bool:
	if row < 0 or row >= Config.GRID_ROWS:
		return false
	if col < 0 or col >= get_row_columns(row):
		return false
	return true

func get_neighbors(col: int, row: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var offsets = NEIGHBORS_ODD if is_row_offset(row) else NEIGHBORS_EVEN
	for offset in offsets:
		var n_col = col + offset.x
		var n_row = row + offset.y
		if is_valid_position(n_col, n_row):
			neighbors.append(Vector2i(n_col, n_row))
	return neighbors

func check_collision(world_pos: Vector2) -> Vector2i:
	for row in range(Config.GRID_ROWS):
		for col in range(get_row_columns(row)):
			if grid[row][col] == null:
				continue
			if world_pos.distance_to(grid_to_world(col, row)) < Config.BUBBLE_RADIUS * Config.COLLISION_FACTOR:
				return Vector2i(col, row)
	return Vector2i(-1, -1)

func check_ceiling_collision(world_pos: Vector2) -> bool:
	return world_pos.y <= Config.TILE_WIDTH / 2.0 + 5

func find_snap_position(world_pos: Vector2) -> Vector2i:
	var base_pos = world_to_grid(world_pos)
	var candidates: Array[Vector2i] = []

	if is_valid_position(base_pos.x, base_pos.y):
		candidates.append(base_pos)
		candidates.append_array(get_neighbors(base_pos.x, base_pos.y))

	var extended: Array[Vector2i] = []
	for pos in candidates:
		if is_valid_position(pos.x, pos.y):
			for neighbor in get_neighbors(pos.x, pos.y):
				if not extended.has(neighbor) and not candidates.has(neighbor):
					extended.append(neighbor)
	candidates.append_array(extended)

	if candidates.is_empty():
		for row in range(maxi(0, base_pos.y - 2), mini(Config.GRID_ROWS, base_pos.y + 3)):
			for col in range(get_row_columns(row)):
				candidates.append(Vector2i(col, row))

	var best_pos = Vector2i(-1, -1)
	var min_dist = INF
	for pos in candidates:
		if not is_valid_position(pos.x, pos.y) or grid[pos.y][pos.x] != null:
			continue
		var dist = world_pos.distance_squared_to(grid_to_world(pos.x, pos.y))
		if dist < min_dist:
			min_dist = dist
			best_pos = pos
	return best_pos

func place_bubble(bubble: Bubble, world_pos: Vector2) -> bool:
	var grid_pos = find_snap_position(world_pos)
	if grid_pos.x < 0:
		return false
	bubble.stop()
	bubble.position = grid_to_world(grid_pos.x, grid_pos.y)
	bubble.grid_position = grid_pos
	bubble.is_attached = true
	grid[grid_pos.y][grid_pos.x] = bubble
	return true

func process_bubble_placement(bubble: Bubble) -> void:
	var cluster = find_cluster(bubble.grid_position.x, bubble.grid_position.y, true)

	if cluster.size() >= Config.MIN_MATCH_COUNT:
		var pop_positions: Array[Vector2] = []
		var drop_positions: Array[Vector2] = []

		for pos in cluster:
			var b = grid[pos.y][pos.x]
			if b:
				pop_positions.append(b.global_position)
				grid[pos.y][pos.x] = null
				b.pop()

		var floating = find_floating_clusters()
		for pos in floating:
			var b = grid[pos.y][pos.x]
			if b:
				drop_positions.append(b.global_position)
				grid[pos.y][pos.x] = null
				b.start_falling()

		bubbles_popped.emit(cluster.size(), floating.size(), pop_positions, drop_positions)
		update_active_colors()
		if is_board_empty():
			board_cleared.emit()
	else:
		bubble_landed.emit()
	check_danger_line()

func find_cluster(start_col: int, start_row: int, match_color: bool) -> Array[Vector2i]:
	var cluster: Array[Vector2i] = []
	var processed: Dictionary = {}
	var queue: Array[Vector2i] = [Vector2i(start_col, start_row)]
	var target_color: int = -1

	if match_color and is_valid_position(start_col, start_row) and grid[start_row][start_col] != null:
		target_color = grid[start_row][start_col].bubble_color

	while not queue.is_empty():
		var pos = queue.pop_front()
		var key = "%d,%d" % [pos.x, pos.y]
		if processed.has(key):
			continue
		processed[key] = true

		if not is_valid_position(pos.x, pos.y) or grid[pos.y][pos.x] == null:
			continue
		if match_color and grid[pos.y][pos.x].bubble_color != target_color:
			continue

		cluster.append(pos)
		for n in get_neighbors(pos.x, pos.y):
			if not processed.has("%d,%d" % [n.x, n.y]):
				queue.append(n)
	return cluster

func find_floating_clusters() -> Array[Vector2i]:
	var floating: Array[Vector2i] = []
	var processed: Dictionary = {}

	for row in range(Config.GRID_ROWS):
		for col in range(get_row_columns(row)):
			if grid[row][col] == null:
				continue
			var key = "%d,%d" % [col, row]
			if processed.has(key):
				continue

			var cluster = find_cluster(col, row, false)
			for pos in cluster:
				processed["%d,%d" % [pos.x, pos.y]] = true

			var anchored = cluster.any(func(pos): return pos.y == 0)
			if not anchored:
				floating.append_array(cluster)
	return floating

func add_row_at_top() -> void:
	# Clear bottom row
	for col in range(get_row_columns(Config.GRID_ROWS - 1)):
		if grid[Config.GRID_ROWS - 1][col] != null:
			grid[Config.GRID_ROWS - 1][col].queue_free()
			grid[Config.GRID_ROWS - 1][col] = null

	# Shift all rows down
	for row in range(Config.GRID_ROWS - 1, 0, -1):
		for col in range(Config.GRID_COLUMNS):
			grid[row][col] = grid[row - 1][col]
			if grid[row][col] != null:
				grid[row][col].grid_position.y = row

	# Clear top row
	for col in range(Config.GRID_COLUMNS):
		grid[0][col] = null

	# Toggle row offset
	row_offset = 1 - row_offset

	# Create new bubbles at row 0
	for col in range(get_row_columns(0)):
		var bubble = bubble_scene.instantiate() as Bubble
		add_child(bubble)
		bubble.set_bubble_color(Bubble.get_random_color())
		bubble.grid_position = Vector2i(col, 0)
		bubble.is_attached = true
		grid[0][col] = bubble
		var target_pos = grid_to_world(col, 0)
		bubble.position = Vector2(target_pos.x, target_pos.y - Config.TILE_HEIGHT)

	# Animate all bubbles
	for row in range(Config.GRID_ROWS):
		for col in range(get_row_columns(row)):
			if grid[row][col] != null:
				var tween = grid[row][col].create_tween()
				tween.tween_property(grid[row][col], "position", grid_to_world(col, row), Config.ROW_SLIDE_DURATION).set_ease(Tween.EASE_OUT)

	update_active_colors()
	get_tree().create_timer(Config.ROW_SLIDE_DURATION).timeout.connect(check_danger_line)

func check_danger_line() -> void:
	for row in range(Config.GRID_ROWS - 2, Config.GRID_ROWS):
		for col in range(get_row_columns(row)):
			if grid[row][col] != null:
				danger_line_reached.emit()
				return

func is_board_empty() -> bool:
	for row in range(Config.GRID_ROWS):
		for col in range(get_row_columns(row)):
			if grid[row][col] != null:
				return false
	return true

func update_active_colors() -> void:
	active_colors.clear()
	var color_set: Dictionary = {}
	for row in range(Config.GRID_ROWS):
		for col in range(get_row_columns(row)):
			if grid[row][col] != null:
				color_set[grid[row][col].bubble_color] = true
	for color in color_set.keys():
		active_colors.append(color)
	if active_colors.is_empty():
		active_colors = [Bubble.BubbleColor.RED, Bubble.BubbleColor.BLUE, Bubble.BubbleColor.GREEN]
	active_colors_changed.emit(active_colors)

func get_active_colors() -> Array[Bubble.BubbleColor]:
	return active_colors

func reset() -> void:
	for row in range(Config.GRID_ROWS):
		for col in range(Config.GRID_COLUMNS):
			if grid[row][col] != null:
				grid[row][col].queue_free()
				grid[row][col] = null
	initialize_grid()
