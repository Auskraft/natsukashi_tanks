import 'dart:math';

import 'run_config.dart';
import 'spawn_director.dart';
import 'tank_entities.dart';
import 'tank_geometry.dart';
import 'tank_grid.dart';
import 'tanks_logic.dart';

/// Размер ростера «Выживания» — практически бесконечная партия (на счёт);
/// игрок почти наверняка падёт раньше, чем зачистит всех.
const int kSurvivalRoster = 120;

/// Открытая арена для «Выживания»: база в кольце + редкие симметричные укрытия.
/// Без seed — недетерминированно (это режим на рекорд, а не общий вызов).
TanksLogic buildSurvival({Random? random}) {
  final rng = random ?? Random();
  final grid = TerrainGrid();

  const ex = 6, ey = 12;
  grid.setTile(ex, ey, TerrainType.base);
  for (final t in const [
    [5, 11],
    [6, 11],
    [7, 11],
    [5, 12],
    [7, 12],
  ]) {
    grid.setTile(t[0], t[1], TerrainType.brick);
  }
  for (final t in const [
    [2, 4],
    [10, 4],
    [2, 8],
    [10, 8],
    [6, 6],
  ]) {
    grid.setTile(t[0], t[1], TerrainType.steel);
  }
  grid
    ..setTile(4, 6, TerrainType.brick)
    ..setTile(8, 6, TerrainType.brick);

  final player = Tank(
    id: 0,
    kind: TankKind.player,
    sx: 3 * TankGeo.sub,
    sy: TankGeo.maxOrigin,
    dir: Dir.up,
    isPlayer: true,
  )..shieldTimer = 3;

  final director = SpawnDirector(
    spawnTiles: const [Point(0, 0), Point(6, 0), Point(11, 0)],
    roster: survivalRoster(rng),
    maxConcurrent: 5,
    interval: 1.6,
    firstDelay: 1.0,
  );

  return TanksLogic(
    grid: grid,
    eagle: Eagle(tileX: ex, tileY: ey),
    player: player,
    director: director,
    config: RunConfig.survival,
    random: rng,
  );
}

/// Эскалирующий ростер: чем дальше — тем больше быстрых/мощных/бронированных.
/// Детерминирован при одинаковом [rng].
List<TankKind> survivalRoster(Random rng) {
  final out = <TankKind>[];
  for (var i = 0; i < kSurvivalRoster; i++) {
    final wave = i / kSurvivalRoster; // 0..1
    final r = rng.nextDouble();
    if (wave < 0.2) {
      out.add(r < 0.85 ? TankKind.basic : TankKind.fast);
    } else if (wave < 0.5) {
      out.add(r < 0.5
          ? TankKind.basic
          : (r < 0.8 ? TankKind.fast : TankKind.power));
    } else if (wave < 0.8) {
      out.add(r < 0.35
          ? TankKind.basic
          : (r < 0.65
              ? TankKind.fast
              : (r < 0.85 ? TankKind.power : TankKind.armor)));
    } else {
      out.add(r < 0.25
          ? TankKind.fast
          : (r < 0.6 ? TankKind.power : TankKind.armor));
    }
  }
  return out;
}
