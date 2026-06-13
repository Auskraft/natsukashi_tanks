import 'tank_entities.dart';

/// Тема мира — задаёт палитру рендера (цвета — на стороне слоя Flame, логика
/// остаётся чистой и без `Color`).
enum TerrainTheme { courtyard, factory, river, grove, proving }

/// Цель на звёзды для уровня: ★ — пройти; +★ за время ≤ [parTimeSec];
/// +★ за прохождение без потери жизни. Итог 1..3.
class StarObjective {
  const StarObjective({this.parTimeSec, this.noDamageStar = true});

  /// Порог времени для второй звезды (сек). null — без «звезды за время».
  final double? parTimeSec;

  /// Давать ли звезду за прохождение без потери жизни.
  final bool noDamageStar;

  int evaluate({required double elapsed, required int livesLost}) {
    var stars = 1;
    if (parTimeSec != null && elapsed <= parTimeSec!) stars++;
    if (noDamageStar && livesLost == 0) stars++;
    return stars > 3 ? 3 : stars;
  }
}

/// Описание уровня: имя, ASCII-карта, ростер врагов, лимит одновременных,
/// цель на звёзды. Карта парсится [parseLevelMap].
class LevelDef {
  const LevelDef({
    required this.name,
    required this.map,
    required this.roster,
    this.maxConcurrent = 4,
    this.isBoss = false,
    this.objective = const StarObjective(),
    this.worldIndex = 0,
  });

  final String name;
  final String map;
  final List<TankKind> roster;
  final int maxConcurrent;
  final bool isBoss;
  final StarObjective objective;
  final int worldIndex;
}

/// Мир: заголовок, тема (палитра), список уровней.
class WorldDef {
  const WorldDef({
    required this.title,
    required this.theme,
    required this.levels,
  });

  final String title;
  final TerrainTheme theme;
  final List<LevelDef> levels;
}
