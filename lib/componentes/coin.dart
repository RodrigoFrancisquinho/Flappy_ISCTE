import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../jogo.dart';
import 'bird.dart';

class Coin extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  Coin({
    required Vector2 position,
    Vector2? size,
  }) : super(
          position: position,
          size: size ?? Vector2.all(24),
          anchor: Anchor.center,
        );

  bool _collected = false;

  final _outerShadow = Paint()..color = const Color(0xFFB8860B);
  final _goldBody = Paint()..color = const Color(0xFFFFD700);
  final _innerRing = Paint()
    ..color = const Color(0xFFFFA500)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final _sparkle = Paint()..color = const Color(0xFFFFF8DC);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    game.collectCoin();
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;

    position.x -= FlappyGame.pipeSpeed * dt;

    if (position.x + size.x / 2 < 0) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is Bird) {
      collect();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final radius = size.x / 2;

    // Outer edge / shadow
    canvas.drawCircle(center, radius, _outerShadow);
    // Main gold body
    canvas.drawCircle(center, radius - 2, _goldBody);
    // Inner decorative ring
    canvas.drawCircle(center, radius - 5, _innerRing);
    // Center shine / highlight
    canvas.drawCircle(center, radius - 8, _sparkle);
  }
}
