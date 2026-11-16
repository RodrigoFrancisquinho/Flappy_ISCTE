import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'componentes/bird.dart';
import 'componentes/coin.dart';
import 'componentes/pipe.dart';

/// The game: owns state, spawns pipes, handles taps.
class FlappyGame extends FlameGame with TapCallbacks, HasCollisionDetection {
  FlappyGame({this.onGameOver});

  final void Function(int score, int coins)? onGameOver;

  static double pipeSpeed = 160;
  static const double pipeWidth = 70;
  static double gapHeight = 300;

  late final Bird bird;
  late final TextComponent scoreText;
  late final TextComponent coinsText;
  late final TextComponent messageText;
  late final TimerComponent spawner;

  final _rng = Random();
  int score = 0;
  int coins = 0;
  bool started = false;
  bool isGameOver = false;

  @override
  Color backgroundColor() => const Color(0xFF70C5CE);

  @override
  Future<void> onLoad() async {
    bird = Bird();

    scoreText = TextComponent(
      text: '0',
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 70),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    coinsText = TextComponent(
      text: '🪙 0',
      anchor: Anchor.topRight,
      position: Vector2(size.x - 20, 20),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
      ),
    );

    messageText = TextComponent(
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.35),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    spawner = TimerComponent(
      period: 1.7,
      repeat: true,
      autoStart: false,
      onTick: _spawnPipes,
    );

    await addAll([bird, scoreText, coinsText, messageText, spawner]);
    _reset();
  }

  void _reset() {
    children.whereType<Pipe>().toList().forEach((p) => p.removeFromParent());
    children.whereType<Coin>().toList().forEach((c) => c.removeFromParent());
    bird.reset(Vector2(size.x * 0.25, size.y / 2));
    score = 0;
    coins = 0;
    scoreText.text = '0';
    coinsText.text = '🪙 0';
    started = false;
    isGameOver = false;
    spawner.timer.stop();
    messageText.text = 'Tap to start';
  }

  void _spawnPipes() {
    const margin = 80.0;
    final maxTop = size.y - margin * 2 - gapHeight;
    final topHeight = margin + _rng.nextDouble() * maxTop;
    final bottomY = topHeight + gapHeight;
    final gapCenterY = topHeight + (gapHeight / 2);
    final coinX = size.x + (pipeWidth / 2);

    addAll([
      Pipe(
        position: Vector2(size.x, 0),
        size: Vector2(pipeWidth, topHeight),
        isScorer: true, // only one pipe per pair awards the point
      ),
      Pipe(
        position: Vector2(size.x, bottomY),
        size: Vector2(pipeWidth, size.y - bottomY),
      ),
      Coin(
        position: Vector2(coinX, gapCenterY),
      ),
    ]);
  }

  void addPoint() {
    score++;
    scoreText.text = '$score';
  }

  void collectCoin() {
    coins++;
    coinsText.text = '🪙 $coins';
  }

  void endGame() {
    if (isGameOver) return;
    isGameOver = true;
    spawner.timer.stop();
    // mandar score para os servers e adicionar pontos ao saldo da conta
    messageText.text = 'Game over\nTap to retry';
    onGameOver?.call(score, coins);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) {
      _reset();
      return;
    }
    if (!started) {
      started = true;
      messageText.text = '';
      spawner.timer.start();
      _spawnPipes();
    }
    bird.flap();
  }
}
