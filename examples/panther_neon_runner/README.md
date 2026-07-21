# Panther Neon Runner

An infinite runner showcase game built entirely in PantherLang.

The game runs as an HTTP web server. A browser-based canvas renderer polls the server at ~60fps for game state and renders everything client-side. All game logic (physics, collision, scoring, input handling) executes server-side in PantherLang.

## Run

```bash
panther run examples/panther_neon_runner/main.pan
```

Open http://localhost:8080 in your browser. Press SPACE / ArrowUp / W to jump and R to restart.

## Architecture

```
Browser (Canvas)           HTTP                    PantherLang Server
┌──────────────┐     POST /in (input)     ┌──────────────────────┐
│  Input queue │ ──────────────────────→  │  Input processing    │
│  Render loop │                          │  Physics (gravity)   │
│  FPS counter │                          │  Obstacle spawning   │
└──────┬───────┘     GET /frame           │  Collision (AABB)    │
       │ ──────────────────────────────→  │  Star parallax       │
       │ ←──────────────────────────────  │  Render commands     │
       │        JSON render commands      │  State persistence   │
       │                                  └──────────────────────┘
```

## Routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | HTML+JS bridge page with canvas renderer |
| GET | `/frame` | Game tick: advance state, return render commands |
| POST | `/in` | Accept input events (keydown/keyup) |
| GET | `/reset` | Reset game state, preserve high score |

## Render Commands

The `/frame` endpoint returns a JSON object with:
- `cmds` — array of render commands
- `s` — current score
- `hs` — high score
- `go` — game over flag

Each command has a `t` (type) field:
- `"c"` — clear screen (fill color)
- `"r"` — rectangle (x, y, w, h, fill color)
- `"o"` — circle (x, y, r, fill color)
- `"t"` — text (string, x, y, font size, fill color)
- `"l"` — line (x1, y1, x2, y2, stroke color, width)

## Features

- Parallax scrolling starfield background (40 stars)
- Animated neon grid on the ground
- Procedural obstacle spawning with increasing difficulty
- AABB collision detection
- Score tracking with persistent high score per session
- Game over overlay with restart
- ~60fps HTTP polling render loop
- SQLite-backed state persistence via `storage_open/put/get`
