# Bubble Shooter, godot example code, Civax 2026 (X: @civaxo, Github @LeanEntropy)
extends Node2D
## Floating score popup that rises up and fades out

@onready var label: Label = $Label

const FLOAT_DISTANCE: float = 80.0
const FLOAT_DURATION: float = 1.0

func setup(score: int, color: Color = Color.WHITE) -> void:
	label.text = "+%d" % score
	label.add_theme_color_override("font_color", color)

	# Animate: float up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, FLOAT_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, FLOAT_DURATION).set_ease(Tween.EASE_IN).set_delay(0.3)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.1)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
