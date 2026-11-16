# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flappy Bird clone** built with **Flutter** and **Flame** game engine. The game features:
- Bird physics with gravity and tap-to-flap mechanics
- Procedurally generated pipe obstacles
- Score tracking
- Game over / restart flow

## Architecture

```
lib/
├── main.dart          # App entry point, MaterialApp, navigation to GamePage
├── jogo.dart          # FlappyGame - core game logic (FlameGame + TapCallbacks + CollisionDetection)
└── componentes/
    ├── bird.dart      # Bird component with physics, rendering, collision handling
    ├── coin.dart      # Coin component spawned in pipe gaps, collectible on bird contact
    └── pipe.dart      # Pipe obstacle with movement, scoring, off-screen cleanup
```

**Key classes:**
- `FlappyGame` (`jogo.dart:12`) - Main game class, owns state, spawns pipes & coins, handles taps
- `Bird` (`componentes/bird.dart:8`) - Player character with gravity/flap physics and custom rendering
- `Coin` (`componentes/coin.dart:8`) - Collectible item spawned between pipes
- `Pipe` (`componentes/pipe.dart:7`) - Obstacle that moves left, awards points when passed

## Commands

### Development
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run in browser
flutter run -d windows         # Run on Windows desktop
```

### Building
```bash
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle
flutter build ios              # iOS (macOS only)
flutter build web              # Web
flutter build windows          # Windows desktop
```

### Testing
```bash
flutter test                   # Run all tests
flutter test test/widget_test.dart  # Run specific test file
```

### Linting & Analysis
```bash
flutter analyze                # Static analysis
dart format .                  # Format code
flutter pub upgrade --major-versions  # Upgrade dependencies
```

### Dependencies
```bash
flutter pub get                # Install dependencies
flutter pub upgrade            # Upgrade within version constraints
flutter pub outdated           # Check for updates
```

## Key Implementation Details

### Game Constants (jogo.dart)
- `pipeSpeed = 160` - Horizontal pipe velocity
- `pipeWidth = 70` - Pipe width
- `gapHeight = 300` - Vertical gap between pipes
- Spawn interval: 1.7 seconds

### Bird Physics (componentes/bird.dart)
- `gravity = 1200` - Downward acceleration
- `flapImpulse = -420` - Upward velocity on tap
- Rotation: `angle = (velocity / 800).clamp(-0.5, 1.0)`

### Scoring
- Only the top pipe in each pair has `isScorer = true`
- Point awarded when pipe's right edge passes bird's x position

### Game States
- `started = false` - Waiting for first tap ("Tap to start")
- `started = true, isGameOver = false` - Playing
- `isGameOver = true` - Game over ("Game over\nTap to retry")

## Testing Notes

The existing `test/widget_test.dart` is a template counter test that doesn't match the actual app. Real game tests would need Flame's test utilities.

## Tech Stack

- **Flutter** 3.13.4+ (Dart SDK)
- **Flame** 1.38.2 - 2D game engine
- **Supabase Flutter** 2.18.3 - Backend (configured but not used in current code)
- **flutter_lints** 6.0.0 - Linting rules

## Git Info

- Main branch: `main`
- Current branch: `gameplay-test-branch`
- Recent commits: "Gameplay test commit" (67bbce6), "Commit inicial" (2679937)