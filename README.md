# Bubble Shooter

A basic example of the classic bubble shooter game built with **Godot 4.5**. Aim, shoot, and match 3+ bubbles of the same color to clear the board before time runs out.

I saw a Godot is missing some basic game examples so I decided to release a few, as a service to other developers. Feel free to use this.

![Godot](https://img.shields.io/badge/Godot-4.5-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Gameplay

- **Objective:** Clear all bubbles from the board to win
- **Time Limit:** 3 minutes per game
- **Controls:**
  - Click and drag to aim, release to shoot
  - Click on the launcher or press Left/Right arrow keys to swap current and next bubble
- **Matching:** Connect 3 or more bubbles of the same color to pop them
- **Wall Bouncing:** Bubbles bounce off side walls for trick shots
- **Floating Bubbles:** Bubbles not connected to the ceiling will fall

## Scoring

| Action | Points |
|--------|--------|
| Pop bubble | 10 |
| Combo (>3 bubbles) | +15 per extra |
| Drop floating bubble | 20 |
| Clear board bonus | remaining seconds × 100 |

## Pressure Mechanic

Every 4 shots without removing bubbles, a new row of bubbles is added at the top. If bubbles reach the danger zone at the bottom, game over!

## Project Structure

```
bubbleshooter/
├── scenes/
│   ├── main.tscn           # Main game scene
│   ├── bubble.tscn         # Bubble entity
│   ├── shooter.tscn        # Shooter/launcher
│   ├── score_popup.tscn    # Floating score text
│   └── ui/                 # UI screens (HUD, game over, leaderboard)
├── scripts/
│   ├── config.gd           # All game parameters (autoload)
│   ├── game_state.gd       # Score, timer, leaderboard (autoload)
│   ├── main.gd             # Main game controller
│   ├── bubble.gd           # Bubble behavior and colors
│   ├── bubble_grid.gd      # Hex grid, matching, collision
│   ├── shooter.gd          # Aiming and shooting mechanics
│   └── ui/                 # UI controllers
└── assets/
    └── sprites/            # Game graphics
```

## Key Technical Features

- **Hexagonal Grid:** Offset coordinate system with alternating 11-10 bubble rows
- **BFS Cluster Detection:** Efficient same-color matching and floating bubble detection
- **Trajectory Preview:** Real-time aim line with wall bounce calculations
- **Active Color Sync:** Shooter bubbles automatically change when their color is cleared from the board

## Running the Game

1. Open the project in Godot 4.5+
2. Press F5 or click the Play button
3. Alternatively, run from command line:
   ```bash
   godot --path . scenes/main.tscn
   ```

## Configuration

All game parameters are in `scripts/config.gd` for easy tuning:
- Screen dimensions
- Grid size and bubble count
- Movement speeds
- Scoring values
- Animation durations

## Credits

- **Code & Design:** [Civax](Ohad Barzilay) (https://x.com/civaxo) ([GitHub](https://github.com/LeanEntropy))
- **Game Assets:** 3 images (bubble image and the bubble switcher bg) made by Kenney.nl (these are CC0. Thanks Kenney!)
- **Engine:** [Godot Engine](https://godotengine.org/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
