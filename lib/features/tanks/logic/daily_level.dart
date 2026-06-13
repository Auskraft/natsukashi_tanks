import 'dart:math';

import 'level_loader.dart';
import 'level_model.dart';
import 'run_config.dart';
import 'tank_entities.dart';
import 'tanks_logic.dart';

/// Seed дня — одинаков у всех в одну дату (детерминированный вызов).
int dailySeed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// Детерминированная карта дня (13×13). База/игрок/спавны — фикс; терреин —
/// симметричный «шум» от seed (зеркалим левую половину в правую, центр-колонка
/// 6 свободна — путь к базе). Всегда валидна для [parseLevelMap].
String dailyMap(int seed) {
  final rng = Random(seed);
  final g = List.generate(13, (_) => List.filled(13, '.'));

  // База-орёл в кольце.
  g[12][6] = 'E';
  g[11][5] = 'B';
  g[11][6] = 'B';
  g[11][7] = 'B';
  g[12][5] = 'B';
  g[12][7] = 'B';
  // Игрок.
  g[11][3] = '1';
  // Точки спавна врагов (верхний ряд).
  g[0][0] = 'a';
  g[0][6] = 'a';
  g[0][11] = 'a';

  // Симметричный шум только в зоне rows 2..9, cols 1..5 (зеркало в 7..11).
  for (var ty = 2; ty <= 9; ty++) {
    for (var tx = 1; tx <= 5; tx++) {
      final roll = rng.nextDouble();
      String c = '.';
      if (roll < 0.18) {
        c = 'B';
      } else if (roll < 0.24) {
        c = 'S';
      } else if (roll < 0.30) {
        c = '~';
      }
      if (c != '.') {
        g[ty][tx] = c;
        g[ty][12 - tx] = c;
      }
    }
  }
  return g.map((r) => r.join()).join('\n');
}

/// Описание уровня дня (карта + ростер, всё от seed даты).
LevelDef dailyLevelDef(DateTime date) {
  final seed = dailySeed(date);
  final rng = Random(seed ^ 0x5151);
  final roster = <TankKind>[];
  const n = 16;
  for (var i = 0; i < n; i++) {
    final r = rng.nextDouble();
    roster.add(r < 0.4
        ? TankKind.basic
        : (r < 0.7
            ? TankKind.fast
            : (r < 0.9 ? TankKind.power : TankKind.armor)));
  }
  return LevelDef(
    name: 'Вызов дня',
    map: dailyMap(seed),
    roster: roster,
    maxConcurrent: 4,
  );
}

/// Собирает играбельный «вызов дня». Одна дата → идентичный прогон у всех.
TanksLogic buildDaily(DateTime date) => buildLevel(
      dailyLevelDef(date),
      config: RunConfig.daily,
      random: Random(dailySeed(date)),
    );
