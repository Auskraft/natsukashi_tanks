import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/storage/game_storage.dart';
import '../logic/level_data.dart';
import '../logic/level_loader.dart';
import 'tanks_game_screen.dart';

/// Экран кампании: миры и сетки уровней со звёздами и блокировкой.
class TanksCampaignScreen extends StatefulWidget {
  const TanksCampaignScreen({super.key});

  @override
  State<TanksCampaignScreen> createState() => _TanksCampaignScreenState();
}

class _TanksCampaignScreenState extends State<TanksCampaignScreen> {
  bool _unlocked(int world, int level) {
    if (world == 0 && level == 0) return true;
    final s = GameStorage.instance;
    if (level > 0) return s.levelStars(world, level - 1) >= 1;
    // Первый уровень мира >0 открыт, если пройден последний уровень прошлого.
    final prevLast = kWorlds[world - 1].levels.length - 1;
    return s.levelStars(world - 1, prevLast) >= 1;
  }

  Future<void> _play(int world, int level) async {
    final lvl = kWorlds[world].levels[level];
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TanksGameScreen(
        title: lvl.name,
        subtitle: 'Защити базу • зачисти врагов',
        mode: TanksMode.campaign,
        theme: kWorlds[world].theme,
        build: () => buildLevel(lvl, random: Random()),
        objective: lvl.objective,
        onStarsEarned: (stars) =>
            GameStorage.instance.setLevelStars(world, level, stars),
      ),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = GameStorage.instance;
    return Scaffold(
      backgroundColor: const Color(0xFF07051A),
      appBar: AppBar(
        title: const Text('Кампания'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF1F0FF),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (var w = 0; w < kWorlds.length; w++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
              child: Text(
                'Мир ${w + 1} · ${kWorlds[w].title}',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF1F0FF),
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var l = 0; l < kWorlds[w].levels.length; l++)
                  _LevelTile(
                    index: l + 1,
                    stars: s.levelStars(w, l),
                    locked: !_unlocked(w, l),
                    onTap: _unlocked(w, l) ? () => _play(w, l) : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.index,
    required this.stars,
    required this.locked,
    this.onTap,
  });

  final int index;
  final int stars;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Material(
        color: locked ? const Color(0x08FFFFFF) : const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                locked ? '🔒' : '$index',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: locked ? 22 : 28,
                  fontWeight: FontWeight.w900,
                  color: locked
                      ? const Color(0xFF6B5E99)
                      : const Color(0xFF4ECDC4),
                ),
              ),
              if (!locked) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= 3; i++)
                      Icon(
                        i <= stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: i <= stars
                            ? const Color(0xFFFFD54F)
                            : Colors.white.withValues(alpha: 0.25),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
