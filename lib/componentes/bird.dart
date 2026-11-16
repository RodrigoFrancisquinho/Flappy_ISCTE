import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../jogo.dart';
import 'coin.dart';
import 'pipe.dart';

class Bird extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  Bird() : super(size: Vector2.all(36), anchor: Anchor.center);

  static double gravity = 1200;
  static const double flapImpulse = -420;

  double velocity = 0;

  final _body = Paint()..color = const Color(0xFFFFD93B);
  final _eye = Paint()..color = Colors.black;
  final _beak = Paint()..color = const Color(0xFFFF8C42);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  void reset(Vector2 startPosition) {
    position = startPosition;
    velocity = 0;
    angle = 0;
  }

  void flap() => velocity = flapImpulse;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.started || game.isGameOver) return;

    velocity += gravity * dt;
    position.y += velocity * dt;
    angle = (velocity / 800).clamp(-0.5, 1.0);

    if (position.y < 0 || position.y > game.size.y) {
      game.endGame();
    }
  }

  @override
  void render(Canvas canvas) {
    final c = (size / 2).toOffset();
    canvas.drawCircle(c, size.x / 2, _body);
    canvas.drawCircle(c + const Offset(7, -6), 4, _eye);
    canvas.drawRect(
      Rect.fromCenter(center: c + const Offset(18, 3), width: 12, height: 8),
      _beak,
    );
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is Pipe) game.endGame();
    if (other is Coin) other.collect();
  }
}

