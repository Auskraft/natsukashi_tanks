import 'dart:math';

import 'tank_entities.dart';
import 'tank_geometry.dart';
import 'tank_grid.dart';

/// Разобранная карта: терреин + позиции орла, спавна игрока и точек спавна
/// врагов (тайловые координаты — верхне-левый угол области 2×2).
class ParsedMap {
  ParsedMap({
    required this.grid,
    required this.eagle,
    required this.playerSpawn,
    required this.enemySpawns,
  });

  final TerrainGrid grid;
  final Eagle eagle;
  final Point<int> playerSpawn;
  final List<Point<int>> enemySpawns;
}

/// Парсит ASCII-карту 13×13 в [ParsedMap]. Бросает [FormatException] на любой
/// некорректной карте — это главная страховка контента (агент не запускает игру).
///
/// Легенда: `.` пусто · `B` кирпич · `S` сталь · `~` вода · `T` лес · `I` лёд ·
/// `E` орёл(база) · `1` спавн игрока · `a` точка спавна врага.
ParsedMap parseLevelMap(String map) {
  final rows = map.trim().split('\n').map((r) => r.trimRight()).toList();
  if (rows.length != TankGeo.tiles) {
    throw FormatException(
        'ожидается ${TankGeo.tiles} строк, получено ${rows.length}');
  }

  final grid = TerrainGrid();
  Point<int>? eagle;
  Point<int>? player;
  final enemies = <Point<int>>[];

  for (var ty = 0; ty < TankGeo.tiles; ty++) {
    final row = rows[ty];
    if (row.length != TankGeo.tiles) {
      throw FormatException(
          'строка $ty: ожидается ${TankGeo.tiles} символов, получено ${row.length}');
    }
    for (var tx = 0; tx < TankGeo.tiles; tx++) {
      final ch = row[tx];
      if (ch == '.') {
        // пусто
      } else if (ch == 'B') {
        grid.setTile(tx, ty, TerrainType.brick);
      } else if (ch == 'S') {
        grid.setTile(tx, ty, TerrainType.steel);
      } else if (ch == '~') {
        grid.setTile(tx, ty, TerrainType.water);
      } else if (ch == 'T') {
        grid.setTile(tx, ty, TerrainType.forest);
      } else if (ch == 'I') {
        grid.setTile(tx, ty, TerrainType.ice);
      } else if (ch == 'E') {
        if (eagle != null) throw const FormatException('более одного орла (E)');
        eagle = Point(tx, ty);
        grid.setTile(tx, ty, TerrainType.base);
      } else if (ch == '1') {
        if (player != null) {
          throw const FormatException('более одного спавна игрока (1)');
        }
        player = Point(tx, ty);
      } else if (ch == 'a') {
        enemies.add(Point(tx, ty));
      } else {
        throw FormatException('неизвестный символ "$ch" в ($tx,$ty)');
      }
    }
  }

  if (eagle == null) throw const FormatException('нет орла (E)');
  if (player == null) throw const FormatException('нет спавна игрока (1)');
  if (enemies.isEmpty) {
    throw const FormatException('нет точек спавна врагов (a)');
  }
  if (enemies.length > 3) {
    throw FormatException('точек спавна врагов > 3: ${enemies.length}');
  }
  _checkArea(player, 'спавн игрока');
  for (final e in enemies) {
    _checkArea(e, 'спавн врага');
  }

  return ParsedMap(
    grid: grid,
    eagle: Eagle(tileX: eagle.x, tileY: eagle.y),
    playerSpawn: player,
    enemySpawns: enemies,
  );
}

/// Область 2×2 танка должна помещаться в поле (верх-левый тайл ≤ tiles-2).
void _checkArea(Point<int> tile, String what) {
  if (tile.x > TankGeo.tiles - 2 || tile.y > TankGeo.tiles - 2) {
    throw FormatException('$what в $tile: область 2×2 выходит за поле');
  }
}
