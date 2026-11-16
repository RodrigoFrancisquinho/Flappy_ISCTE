import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../jogo.dart';

class Pipe extends PositionComponent with HasGameReference<FlappyGame> {
  Pipe({
    required Vector2 position,
    required Vector2 size,
    this.isScorer = false,
  }) : super(position: position, size: size);

  final bool isScorer;
  bool _scored = false;

  final _fill = Paint()..color = const Color(0xFF3FA34D);
  final _stroke = Paint()
    ..color = const Color(0xFF2B7A36)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;

    position.x -= FlappyGame.pipeSpeed * dt;

    if (isScorer && !_scored && position.x + size.x < game.bird.position.x) {
      _scored = true;
      game.addPoint();
    }
    if (position.x + size.x < 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _fill);
    canvas.drawRect(size.toRect(), _stroke);
  }
}