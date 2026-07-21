# PantherLang Calculator Pro

A professional server-side calculator demonstrating PantherLang 2.0's web platform capabilities.

## Quick Start

```bash
panther run examples/panther_calculator_pro/main.pan
```

Open http://127.0.0.1:9090/ in your browser.

## Features

- **Basic Calculator**: +, -, *, /, ^, %, decimal, backspace, clear
- **Scientific Functions**: sqrt, cbrt, abs, factorial, pow, gcd, lcm, pi, e, random, sign, round, floor, ceil, clamp, lerp, deg/rad conversion
- **Statistical Functions**: mean, median, stddev
- **Memory**: MC, MR, MS, M+, M- (server-persisted)
- **History**: Persistent calculation history with server-side storage
- **5 Themes**: Dark, Light, Cyber, Matrix, Midnight (persisted in localStorage)
- **Keyboard Support**: Full keyboard input
- **Inspiration**: Explain This (AI explanation stub with graceful fallback)
- **Responsive**: Desktop and mobile layouts

## Architecture

| Component | Technology |
|-----------|-----------|
| Web Server | `panther.web` (functional API) |
| Math Engine | `panther.math` (30+ functions) |
| Persistence | `panther.storage` (key-value store) |
| Serialization | `panther.json` (parse/stringify) |
| Client UI | Server-rendered HTML + vanilla JavaScript |

## API Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/` | Calculator web application |
| GET | `/health` | Health check |
| POST | `/api/calculate` | Evaluate expression |
| GET | `/api/history` | Retrieve calculation history |
| POST | `/api/history` | Save history entry |
| DELETE | `/api/history` | Clear all history |
| POST | `/api/memory` | Save memory value |
| GET | `/api/memory` | Retrieve memory value |
| POST | `/api/explain` | AI explanation stub |

## Server-Side Math

All scientific functions execute server-side via `panther.math`:

- Single-arg: `sqrt(16)`, `factorial(5)`, `abs(-10)`, `pi()`, `e()`
- Two-arg: `pow(2, 10)`, `gcd(12, 8)`, `random(1, 100)`
- Three-arg: `clamp(5, 0, 10)`, `lerp(0, 100, 0.5)`
- Expression: `10 + 20 * 3`, `100 / 7`, `2 ^ 8`

## Development

Built as a single-file application within PantherLang's module system constraints.
