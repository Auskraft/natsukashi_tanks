import 'package:flutter_test/flutter_test.dart';
import 'package:natsukashi_tanks/features/tanks/logic/daily_level.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tank_entities.dart';
import 'package:natsukashi_tanks/features/tanks/logic/tanks_logic.dart';

void main() {
  group('ежедневный вызов', () {
    test('карта дня детерминирована по дате', () {
      final d = DateTime(2026, 6, 13);
      expect(dailyMap(dailySeed(d)), dailyMap(dailySeed(d)));
    });

    test('карта дня собирается в играбельный уровень', () {
      final g = buildDaily(DateTime(2026, 6, 13));
      expect(g.over, isFalse);
      expect(g.eagle.destroyed, isFalse);
      expect(g.grid.solidForTank(g.player.sx, g.player.sy), isFalse);
      expect(g.enemiesRemaining, greaterThan(0));
    });

    test('одна дата → идентичный прогон (детерминизм симуляции)', () {
      final a = buildDaily(DateTime(2026, 6, 13));
      final b = buildDaily(DateTime(2026, 6, 13));
      for (var i = 0; i < 60; i++) {
        a.step(0.05, const PlayerIntent(move: Dir.up, fire: true));
        b.step(0.05, const PlayerIntent(move: Dir.up, fire: true));
      }
      expect(a.score, b.score);
      expect(a.player.sx, b.player.sx);
      expect(a.player.sy, b.player.sy);
      expect(a.enemiesAlive, b.enemiesAlive);
    });

    test('разные даты — разные карты', () {
      final m1 = dailyMap(dailySeed(DateTime(2026, 6, 13)));
      final m2 = dailyMap(dailySeed(DateTime(2026, 6, 14)));
      expect(m1, isNot(m2));
    });
  });
}
