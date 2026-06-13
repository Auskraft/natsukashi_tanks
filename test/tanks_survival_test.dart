import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:natsukashi_tanks/features/tanks/logic/survival.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_entities.dart';

void main() {
  group('выживание', () {
    test('ростер детерминирован по seed', () {
      expect(survivalRoster(Random(7)), survivalRoster(Random(7)));
    });

    test('сложность растёт: тяжёлых врагов больше во второй половине', () {
      final r = survivalRoster(Random(3));
      int hard(Iterable<TankKind> xs) =>
          xs.where((k) => k == TankKind.power || k == TankKind.armor).length;
      final half = r.length ~/ 2;
      expect(hard(r.skip(half)), greaterThan(hard(r.take(half))));
    });

    test('buildSurvival: игрок не в стене, спавны есть, не закончено', () {
      final g = buildSurvival(random: Random(1));
      expect(g.over, isFalse);
      expect(g.enemiesRemaining, greaterThan(0));
      expect(g.grid.solidForTank(g.player.sx, g.player.sy), isFalse);
    });
  });
}
