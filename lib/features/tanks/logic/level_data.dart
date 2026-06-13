import 'level_model.dart';
import 'tank_entities.dart';

// Карты 13×13. Легенда: . пусто · B кирпич · S сталь · ~ вода · T лес · I лёд ·
//   E орёл(база) · 1 спавн игрока (верх-левый угол 2×2) · a точка спавна врага.
// База: орёл (6,12) в кирпичном кольце (5-7,11 + 5,7,12). Игрок: (3,11).

const String _l1 = '''
......a......
.............
.............
...BB...BB...
...BB...BB...
.............
.............
.....B.B.....
.............
.............
.............
...1.BBB.....
.....BEB.....
''';

const String _l2 = '''
a.....a......
.............
..BBB...BBB..
.............
....B...B....
....B...B....
.............
..BBB...BBB..
.............
.............
.............
...1.BBB.....
.....BEB.....
''';

const String _l3 = '''
a.....a....a.
.............
.SS.......SS.
.............
...B.....B...
...B.....B...
...B.....B...
.............
.SS.......SS.
.............
.............
...1.BBB.....
.....BEB.....
''';

const String _l4 = '''
a.....a....a.
.............
.BBB.....BBB.
.B.........B.
...~~~.~~~...
.............
....BB.BB....
.............
.B.........B.
.BBB.....BBB.
.............
...1.BBB.....
.....BEB.....
''';

const String _l5 = '''
a.....a....a.
..B.B.B.B.B..
.............
.SS.BBB.BB.S.
.............
..II.....II..
.............
.S.BB.BB.SS..
.............
..B.B.B.B.B..
.............
...1.BBB.....
.....BEB.....
''';

const String _l6 = '''
a.....a....a.
.SS.B.B.B.SS.
.............
.B.BB...BB.B.
.B.........B.
...S.....S...
..~~..B..~~..
...S.....S...
.B.........B.
.B.BB...BB.B.
.............
...1.BBB.....
.....BEB.....
''';

/// Реестр миров. Фаза 4 — мир 1 «Двор» (тема courtyard, кирпич). Остальные
/// миры и боссы добавляются в фазе 7.
const List<WorldDef> kWorlds = [
  WorldDef(
    title: 'Двор',
    theme: TerrainTheme.courtyard,
    levels: [
      LevelDef(
        name: '1 · Первый бой',
        map: _l1,
        roster: [TankKind.basic, TankKind.basic, TankKind.basic],
        maxConcurrent: 2,
        objective: StarObjective(parTimeSec: 40),
      ),
      LevelDef(
        name: '2 · Дворы',
        map: _l2,
        roster: [
          TankKind.basic,
          TankKind.basic,
          TankKind.fast,
          TankKind.basic,
          TankKind.basic,
        ],
        maxConcurrent: 3,
        objective: StarObjective(parTimeSec: 55),
      ),
      LevelDef(
        name: '3 · Коридоры',
        map: _l3,
        roster: [
          TankKind.basic,
          TankKind.fast,
          TankKind.basic,
          TankKind.power,
          TankKind.fast,
          TankKind.basic,
        ],
        maxConcurrent: 3,
        objective: StarObjective(parTimeSec: 70),
      ),
      LevelDef(
        name: '4 · Завалы',
        map: _l4,
        roster: [
          TankKind.basic,
          TankKind.fast,
          TankKind.power,
          TankKind.basic,
          TankKind.fast,
          TankKind.armor,
          TankKind.basic,
        ],
        maxConcurrent: 4,
        objective: StarObjective(parTimeSec: 85),
      ),
      LevelDef(
        name: '5 · Теснина',
        map: _l5,
        roster: [
          TankKind.fast,
          TankKind.basic,
          TankKind.power,
          TankKind.armor,
          TankKind.fast,
          TankKind.basic,
          TankKind.power,
          TankKind.basic,
        ],
        maxConcurrent: 4,
        objective: StarObjective(parTimeSec: 100),
      ),
      LevelDef(
        name: '6 · Рубеж',
        map: _l6,
        roster: [
          TankKind.armor,
          TankKind.power,
          TankKind.fast,
          TankKind.basic,
          TankKind.power,
          TankKind.fast,
          TankKind.armor,
          TankKind.basic,
        ],
        maxConcurrent: 4,
        objective: StarObjective(parTimeSec: 120),
      ),
    ],
  ),
];
