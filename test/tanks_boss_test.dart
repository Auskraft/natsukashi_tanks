import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_entities.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_grid.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tanks_logic.dart';

void main() {
  group('босс', () {
    test('выдерживает столько попаданий, сколько его hp', () {
      final boss = Tank(
          id: 5, kind: TankKind.boss, sx: 40, sy: 0, dir: Dir.down, isPlayer: false)
        ..freezeTimer = 999; // фиксируем как мишень
      final g = TanksLogic(
        grid: TerrainGrid(),
        eagle: Eagle(tileX: 6, tileY: 12),
        player: Tank(
            id: 0,
            kind: TankKind.player,
            sx: 0,
            sy: 40,
            dir: Dir.right,
            isPlayer: true),
        enemies: [boss],
        enemiesRemaining: 99,
        random: Random(1),
      );
      final hp = kTankSpecs[TankKind.boss]!.hp;

      for (var i = 0; i < hp - 1; i++) {
        g.bullets.add(Bullet(
            id: 100 + i,
            ownerId: 0,
            owner: BulletOwner.player,
            x: 30,
            y: 6,
            dir: Dir.right,
            speed: 400,
            power: 1));
        for (var k = 0; k < 4; k++) {
          g.step(0.05, PlayerIntent.idle);
        }
      }
      expect(boss.alive, isTrue, reason: 'на одно попадание меньше hp — ещё жив');

      g.bullets.add(Bullet(
          id: 999,
          ownerId: 0,
          owner: BulletOwner.player,
          x: 30,
          y: 6,
          dir: Dir.right,
          speed: 400,
          power: 1));
      var dead = false;
      for (var k = 0; k < 4 && !dead; k++) {
        if (g.step(0.05, PlayerIntent.idle).tanksDestroyed.isNotEmpty) {
          dead = true;
        }
      }
      expect(dead, isTrue);
    });
  });
}
