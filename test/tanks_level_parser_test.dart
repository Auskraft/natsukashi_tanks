import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:natsukashi_tanks/features/tanks/logic/level_data.dart';
import 'package:natsukashi_tanks/features/tanks/logic/level_loader.dart';
import 'package:natsukashi_tanks/features/tanks/logic/level_model.dart';
import 'package:natsukashi_tanks/features/tanks/logic/level_parser.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_geometry.dart';

void main() {
  group('парсер уровней', () {
    test('парсит ВСЕ уровни kWorlds корректно', () {
      var count = 0;
      for (final w in kWorlds) {
        for (final lvl in w.levels) {
          final m = parseLevelMap(lvl.map);
          expect(m.enemySpawns, isNotEmpty, reason: lvl.name);
          count++;
        }
      }
      final expected =
          kWorlds.fold<int>(0, (a, w) => a + w.levels.length);
      expect(count, expected);
      expect(count, greaterThanOrEqualTo(20));
    });

    test('buildLevel собирает играбельную логику; игрок не в стене', () {
      for (final w in kWorlds) {
        for (final lvl in w.levels) {
          final g = buildLevel(lvl, random: Random(1));
          expect(g.over, isFalse, reason: lvl.name);
          expect(g.enemiesRemaining, lvl.roster.length, reason: lvl.name);
          final p = g.player;
          const last = TankGeo.tankSize - 1;
          expect(g.grid.solidForTank(p.sx, p.sy), isFalse, reason: lvl.name);
          expect(g.grid.solidForTank(p.sx + last, p.sy + last), isFalse,
              reason: lvl.name);
        }
      }
    });

    test('мальформы бросают FormatException', () {
      expect(() => parseLevelMap('короткая'), throwsFormatException);
      expect(() => parseLevelMap('.............\n.............'),
          throwsFormatException);
      final noEagle = List.filled(13, '.' * 13).join('\n');
      expect(() => parseLevelMap(noEagle), throwsFormatException);
      final badChar = List.filled(13, '.' * 13).toList()..[0] = 'X${'.' * 12}';
      expect(() => parseLevelMap(badChar.join('\n')), throwsFormatException);
    });

    test('звёзды: 1 базовая, +1 за время, +1 без урона', () {
      const obj = StarObjective(parTimeSec: 60);
      expect(obj.evaluate(elapsed: 30, livesLost: 0), 3);
      expect(obj.evaluate(elapsed: 30, livesLost: 1), 2);
      expect(obj.evaluate(elapsed: 90, livesLost: 1), 1);
    });
  });
}
