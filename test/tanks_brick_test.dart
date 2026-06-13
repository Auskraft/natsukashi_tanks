import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_entities.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_grid.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tanks_logic.dart';

void main() {
  group('разрушение кирпича половинами', () {
    test('chipBrickQuads сносит заданную половину; тайл чист за 2 половины', () {
      final g = TerrainGrid()..setTile(5, 5, TerrainType.brick);
      expect(g.chipBrickQuads(5, 5, 0x5), isTrue); // левый столбец (TL|BL)
      expect(g.quadMaskAt(5, 5), 0xA); // осталась правая половина
      expect(g.typeAt(5, 5), TerrainType.brick);
      expect(g.chipBrickQuads(5, 5, 0xA), isTrue); // правый столбец
      expect(g.typeAt(5, 5), TerrainType.empty);
      expect(g.chipBrickQuads(5, 5, 0x5), isFalse); // уже пусто
    });

    test('выстрел сносит половину кирпичного тайла за раз', () {
      final grid = TerrainGrid()
        ..setTile(8, 0, TerrainType.brick)
        ..setTile(8, 1, TerrainType.brick);
      final g = TanksLogic(
        grid: grid,
        eagle: Eagle(tileX: 6, tileY: 12),
        player: Tank(
            id: 0,
            kind: TankKind.player,
            sx: 0,
            sy: 40,
            dir: Dir.right,
            isPlayer: true),
        enemiesRemaining: 99,
        random: Random(1),
      );
      g.bullets.add(Bullet(
          id: 1,
          ownerId: 0,
          owner: BulletOwner.player,
          x: 10,
          y: 6,
          dir: Dir.right,
          speed: 2000,
          power: 1));
      final s = g.step(0.05, PlayerIntent.idle);

      expect(s.bricksHit, isNotEmpty);
      final m = grid.quadMaskAt(8, 0);
      expect(m, greaterThan(0), reason: 'половина тайла ещё стоит');
      expect(m, lessThan(0xF), reason: 'половина снесена');
      expect(grid.typeAt(8, 0), TerrainType.brick);
    });
  });
}
