import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_entities.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_geometry.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_grid.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tanks_logic.dart';

void main() {
  test('упёршийся враг находит свободный выход (не «тупит»)', () {
    // Враг 2×2 на тайлах (5,5)-(6,6), стальная коробка, открыт только верх.
    final grid = TerrainGrid()
      ..setTile(4, 5, TerrainType.steel)
      ..setTile(4, 6, TerrainType.steel) // слева
      ..setTile(7, 5, TerrainType.steel)
      ..setTile(7, 6, TerrainType.steel) // справа
      ..setTile(5, 7, TerrainType.steel)
      ..setTile(6, 7, TerrainType.steel); // снизу

    final enemy = Tank(
      id: 1,
      kind: TankKind.basic,
      sx: 5 * TankGeo.sub,
      sy: 5 * TankGeo.sub,
      dir: Dir.down,
      isPlayer: false,
    );
    final g = TanksLogic(
      grid: grid,
      eagle: Eagle(tileX: 6, tileY: 12),
      player: Tank(
          id: 0,
          kind: TankKind.player,
          sx: 0,
          sy: TankGeo.maxOrigin,
          dir: Dir.up,
          isPlayer: true),
      enemies: [enemy],
      enemiesRemaining: 99,
      random: Random(1),
    );

    final startY = enemy.sy;
    var minSy = enemy.sy;
    for (var i = 0; i < 40; i++) {
      g.step(0.05, PlayerIntent.idle);
      if (enemy.sy < minSy) minSy = enemy.sy;
    }
    expect(minSy, lessThan(startY), reason: 'враг должен был уйти вверх (выход)');
  });
}
