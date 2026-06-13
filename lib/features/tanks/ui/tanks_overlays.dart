import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';
import '../game/tanks_flame_game.dart';

/// HUD боя: счёт, осталось врагов, жизни и кнопка паузы.
class TanksHud extends StatelessWidget {
  const TanksHud({super.key, required this.game});

  final TanksFlameGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: game.score,
                  builder: (_, v, _) => StatBlock(label: 'СЧЁТ', value: '$v'),
                ),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: game.enemiesLeft,
                  builder: (_, v, _) => StatBlock(
                    label: 'ВРАГИ',
                    value: '$v',
                    color: const Color(0xFFFF8A8A),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: game.lives,
                      builder: (_, v, _) => _Hearts(lives: v),
                    ),
                    const SizedBox(height: 8),
                    PauseButton(onTap: game.togglePause),
                  ],
                ),
              ],
            ),
            ValueListenableBuilder<double>(
              valueListenable: game.bossHp,
              builder: (_, hp, _) =>
                  hp < 0 ? const SizedBox.shrink() : _BossBar(fraction: hp),
            ),
          ],
        ),
      ),
    );
  }
}

/// Жизни игрока значками-танками.
class _Hearts extends StatelessWidget {
  const _Hearts({required this.lives});

  final int lives;

  @override
  Widget build(BuildContext context) {
    final n = lives.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Icon(Icons.shield_moon, color: Color(0xFF4ECDC4), size: 18),
          ),
      ],
    );
  }
}

/// Итоговая панель партии: победа/поражение, счёт, звёзды (кампания) либо рекорд.
class TanksResultPanel extends StatelessWidget {
  const TanksResultPanel({
    super.key,
    required this.win,
    required this.score,
    required this.onRetry,
    required this.onExit,
    this.stars,
    this.best,
  });

  final bool win;
  final int score;
  final int? stars;
  final int? best;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return GameScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(win ? '🏆' : '💥', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text(
            win ? 'ПОБЕДА!' : 'База потеряна',
            style: TextStyle(
              color: win ? const Color(0xFFFFD54F) : const Color(0xFFFF8A8A),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          if (stars != null) ...[
            const SizedBox(height: 14),
            _StarsRow(stars: stars!),
          ],
          const SizedBox(height: 18),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (best != null)
            Text('рекорд: $best',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          PlayButton(label: 'ЕЩЁ РАЗ', onTap: onRetry),
          TextButton(
            onPressed: onExit,
            child: Text('Выход',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i <= stars
                  ? const Color(0xFFFFD54F)
                  : Colors.white.withValues(alpha: 0.3),
              size: 40,
            ),
          ),
      ],
    );
  }
}

/// Полоса здоровья босса (показывается в HUD, когда на поле есть босс).
class _BossBar extends StatelessWidget {
  const _BossBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('БОСС',
              style: TextStyle(
                color: Color(0xFFFF6FAE),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6FAE)),
            ),
          ),
        ],
      ),
    );
  }
}
