# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends Node

# =============================================================================
# SCREEN
# =============================================================================
const SCREEN_WIDTH: float = 720.0
const SCREEN_HEIGHT: float = 1280.0

# =============================================================================
# GRID STRUCTURE
# =============================================================================
const GRID_COLUMNS: int = 11
const GRID_ROWS: int = 16
const INITIAL_ROWS: int = 6

# Derived grid dimensions (based on full-width coverage)
var TILE_WIDTH: float
var TILE_HEIGHT: float
var ROW_OFFSET_PX: float
var BUBBLE_RADIUS: float
var LEFT_WALL: float
var RIGHT_WALL: float

# =============================================================================
# MOVEMENT SPEEDS
# =============================================================================
const SHOOT_SPEED: float = 1800.0
const FALL_ACCELERATION: float = 2400.0
const ROW_SLIDE_DURATION: float = 0.15

# =============================================================================
# COLLISION
# =============================================================================
const COLLISION_FACTOR: float = 1.4  # Multiplier for collision detection (< 2.0 allows gaps)

# =============================================================================
# AIMING
# =============================================================================
const MIN_AIM_ANGLE: float = 10.0  # degrees from horizontal
const MAX_AIM_ANGLE: float = 170.0  # degrees from horizontal

# =============================================================================
# GAME RULES
# =============================================================================
const GAME_DURATION: float = 180.0  # seconds (3 minutes)
const TURNS_UNTIL_NEW_LINE: int = 4
const MIN_MATCH_COUNT: int = 3  # bubbles needed to pop

# =============================================================================
# SCORING
# =============================================================================
const BASE_BUBBLE_SCORE: int = 10
const COMBO_BONUS_PER_BUBBLE: int = 15  # for each bubble beyond MIN_MATCH_COUNT
const DROP_BONUS: int = 20
const TIME_BONUS_MULTIPLIER: int = 100  # points per second remaining

# =============================================================================
# UI / LAUNCHER
# =============================================================================
const LAUNCHER_RADIUS: float = 70.0
const NEXT_BUBBLE_SCALE: float = 0.75

# =============================================================================
# ANIMATIONS
# =============================================================================
const BUBBLE_SWAP_DURATION: float = 0.2
const BUBBLE_ADVANCE_DURATION: float = 0.15
const POP_ANIMATION_DURATION: float = 0.12
const FALL_SQUASH_DURATION: float = 0.08

func _ready() -> void:
	_calculate_derived_values()

func _calculate_derived_values() -> void:
	TILE_WIDTH = SCREEN_WIDTH / GRID_COLUMNS
	TILE_HEIGHT = TILE_WIDTH * 0.866  # hex packing ratio
	ROW_OFFSET_PX = TILE_WIDTH / 2.0
	BUBBLE_RADIUS = TILE_WIDTH / 2.0
	LEFT_WALL = BUBBLE_RADIUS
	RIGHT_WALL = SCREEN_WIDTH - BUBBLE_RADIUS
