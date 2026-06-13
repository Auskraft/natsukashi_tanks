import 'dart:math';

import 'level_model.dart';
import 'level_parser.dart';
import 'run_config.dart';
import 'spawn_director.dart';
import 'tank_entities.dart';
import 'tank_geometry.dart';
import 'tanks_logic.dart';

/// Собирает играбельную [TanksLogic] из описания уровня: парсит карту, ставит
/// игрока (с короткой форой-щитом), заводит спавн-директор по ростеру.
TanksLogic buildLevel(
  LevelDef def, {
  RunConfig config = RunConfig.campaign,
  Random? random,
}) {
  final m = parseLevelMap(def.map);
  final player = Tank(
    id: 0,
    kind: TankKind.player,
    sx: m.playerSpawn.x * TankGeo.sub,
    sy: m.playerSpawn.y * TankGeo.sub,
    dir: Dir.up,
    isPlayer: true,
  )..shieldTimer = 3;
  final director = SpawnDirector(
    spawnTiles: m.enemySpawns,
    roster: def.roster,
    maxConcurrent: def.maxConcurrent,
  );
  return TanksLogic(
    grid: m.grid,
    eagle: m.eagle,
    player: player,
    director: director,
    config: config,
    random: random,
  );
}
