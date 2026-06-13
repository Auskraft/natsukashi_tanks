import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/components/dpad_control.dart';
import '../../../core/components/overlay_kit.dart';
import '../../../core/storage/game_storage.dart';
import '../game/tanks_flame_game.dart';
import '../logic/level_model.dart';
import '../logic/tank_entities.dart';
import '../logic/tanks_logic.dart';
import '../ui/tanks_overlays.dart';

/// Режим запуска боя.
enum TanksMode { campaign, survival, daily }

/// Экран-хост боя: держит [TanksFlameGame] (строит партию через [build]), рисует
/// оверлеи по фазе/паузе, D-pad + огонь, и сохраняет результат под режим
/// (звёзды кампании / рекорд выживания / отметку и рекорд дня).
class TanksGameScreen extends StatefulWidget {
  const TanksGameScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.theme,
    required this.build,
    this.objective,
    this.onStarsEarned,
  });

  final String title;
  final String subtitle;
  final TanksMode mode;
  final TerrainTheme theme;
  final TanksLogic Function() build;

  /// Кампания: цель для расчёта звёзд.
  final StarObjective? objective;

  /// Кампания: сохранить заработанные звёзды (вызывается при победе).
  final void Function(int stars)? onStarsEarned;

  @override
  State<TanksGameScreen> createState() => _TanksGameScreenState();
}

class _TanksGameScreenState extends State<TanksGameScreen> {
  late final TanksFlameGame _game;
  TanksResult? _result;
  int _stars = 0;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _best = _loadBest();
    _game = TanksFlameGame(
      build: widget.build,
      theme: widget.theme,
      onResult: _onResult,
    );
  }

  int _loadBest() {
    final s = GameStorage.instance;
    return switch (widget.mode) {
      TanksMode.survival => s.highScore('tanks_survival'),
      TanksMode.daily => s.dailyBest,
      TanksMode.campaign => 0,
    };
  }

  void _startRun() {
    unawaited(GameStorage.instance.registerPlay(DateTime.now()));
    _game.start();
  }

  void _onResult(TanksResult r) {
    final s = GameStorage.instance;
    switch (widget.mode) {
      case TanksMode.campaign:
        _stars = r.win
            ? (widget.objective
                    ?.evaluate(elapsed: r.elapsed, livesLost: r.livesLost) ??
                1)
            : 0;
        if (r.win && _stars > 0) widget.onStarsEarned?.call(_stars);
      case TanksMode.survival:
        unawaited(s.submitScore('tanks_survival', r.score));
        if (r.score > _best) _best = r.score;
      case TanksMode.daily:
        unawaited(s.markDailyDone(DateTime.now()));
        unawaited(s.submitDailyScore(r.score));
        if (r.score > _best) _best = r.score;
    }
    setState(() => _result = r);
  }

  void _exit() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      _game.toReady();
    }
  }

  Dir? _toDir(AxisDirection? a) => switch (a) {
        null => null,
        AxisDirection.up => Dir.up,
        AxisDirection.down => Dir.down,
        AxisDirection.left => Dir.left,
        AxisDirection.right => Dir.right,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<TanksFlameGame>(game: _game),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_game.phase, _game.isPaused]),
              builder: (context, _) {
                if (_game.isPaused.value) {
                  return PausePanel(
                    onResume: _game.togglePause,
                    onRestart: _startRun,
                    onExit: _exit,
                  );
                }
                switch (_game.phase.value) {
                  case TanksPhase.ready:
                    return ReadyPanel(
                      emoji: '🪖',
                      title: widget.title,
                      subtitle: widget.subtitle,
                      onStart: _startRun,
                    );
                  case TanksPhase.running:
                    return Stack(
                      children: [
                        TanksHud(game: _game),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SafeArea(
                            top: false,
                            child: DpadControl(
                              onDirection: (a) => _game.setMoveDir(_toDir(a)),
                              onFireChanged: _game.setFire,
                            ),
                          ),
                        ),
                      ],
                    );
                  case TanksPhase.dead:
                    final r = _result;
                    final win = r?.win ?? false;
                    return TanksResultPanel(
                      win: win,
                      score: r?.score ?? 0,
                      stars: widget.mode == TanksMode.campaign && win
                          ? _stars
                          : null,
                      best: widget.mode == TanksMode.campaign ? null : _best,
                      onRetry: _startRun,
                      onExit: _exit,
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
