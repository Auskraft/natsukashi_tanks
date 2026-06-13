import 'dart:async';
import 'dart:io' show Platform;

import 'package:flame_audio/flame_audio.dart';

import '../storage/game_storage.dart';

/// Фоновые музыкальные дорожки. Имя файла — в [AudioManager._musicFiles].
enum MusicTrack { menu, battle, boss }

/// Дискретные звуковые события игры. Имя файла + базовый микс — в
/// [AudioManager._sfxSpecs]. Слой Flame дёргает [AudioManager.play] на эти
/// события из `TankStep` (рядом с хаптикой).
enum SfxEvent {
  playerShoot,
  enemyShoot,
  brickHit,
  steelHit,
  bulletClash,
  explosion,
  bossExplosion,
  tankSpawn,
  powerUpAppear,
  powerUpTaken,
  upgrade,
  playerHit,
  baseAlarm,
  waveClear,
  victory,
  gameOver,
  uiTap,
}

/// Спецификация SFX: имя файла в `assets/audio/` + базовая громкость
/// (относительный микс, домножается на общий уровень SFX). Частые/тихие
/// события (выстрел, спавн) приглушены, акценты (взрыв, победа) — громче.
class _SfxSpec {
  const _SfxSpec(this.file, this.gain);
  final String file;
  final double gain;
}

/// Единая точка управления звуком: зацикленная музыка (через [FlameAudio.bgm]),
/// короткие SFX (через [FlameAudio.play], low-latency), дакинг музыки под
/// акценты, громкость/мьют (персист в [GameStorage]) и прелоад кэша.
///
/// **Безопасно до появления файлов.** Пока в `assets/audio/` нет клипов (их
/// кладёт владелец по манифесту `docs/AUDIO.md`), любое обращение к платформе/
/// ассетам падает и **глушится** в [_safe]/[_safeAwait] — приложение играет
/// молча и не падает. Контракт имён файлов — в [_musicFiles]/[_sfxSpecs].
///
/// **Безопасно в тестах.** Под `flutter test` (нет аудио-платформы, а сам
/// конструктор `AudioPlayer` кидает async-ошибку) весь слой превращается в
/// no-op через [_inTest] — `FlameAudio.bgm` даже не инициализируется.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  /// Под `flutter test` не трогаем платформу вовсе (иначе ленивый
  /// `FlameAudio.bgm` создаёт `AudioPlayer` и роняет тест async-ошибкой).
  static final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

  // ── Контракт имён файлов (с docs/AUDIO.md и assets/audio/) ─────────────────
  static const Map<MusicTrack, String> _musicFiles = {
    MusicTrack.menu: 'music_menu.ogg',
    MusicTrack.battle: 'music_battle.ogg',
    MusicTrack.boss: 'music_boss.ogg',
  };

  static const Map<SfxEvent, _SfxSpec> _sfxSpecs = {
    SfxEvent.playerShoot: _SfxSpec('sfx_shoot_player.ogg', 0.55),
    SfxEvent.enemyShoot: _SfxSpec('sfx_shoot_enemy.ogg', 0.38),
    SfxEvent.brickHit: _SfxSpec('sfx_brick.ogg', 0.55),
    SfxEvent.steelHit: _SfxSpec('sfx_steel.ogg', 0.55),
    SfxEvent.bulletClash: _SfxSpec('sfx_clash.ogg', 0.6),
    SfxEvent.explosion: _SfxSpec('sfx_explosion.ogg', 0.85),
    SfxEvent.bossExplosion: _SfxSpec('sfx_explosion_big.ogg', 1.0),
    SfxEvent.tankSpawn: _SfxSpec('sfx_spawn.ogg', 0.5),
    SfxEvent.powerUpAppear: _SfxSpec('sfx_powerup_appear.ogg', 0.5),
    SfxEvent.powerUpTaken: _SfxSpec('sfx_powerup.ogg', 0.8),
    SfxEvent.upgrade: _SfxSpec('sfx_upgrade.ogg', 0.85),
    SfxEvent.playerHit: _SfxSpec('sfx_player_hit.ogg', 0.9),
    SfxEvent.baseAlarm: _SfxSpec('sfx_base_alarm.ogg', 0.85),
    SfxEvent.waveClear: _SfxSpec('sfx_wave_clear.ogg', 0.9),
    SfxEvent.victory: _SfxSpec('sfx_victory.ogg', 1.0),
    SfxEvent.gameOver: _SfxSpec('sfx_gameover.ogg', 1.0),
    SfxEvent.uiTap: _SfxSpec('sfx_ui_tap.ogg', 0.55),
  };

  // ── Состояние/настройки ────────────────────────────────────────────────────
  bool _muted = false;
  double _musicVolume = 0.6;
  double _sfxVolume = 0.85;
  bool _initialized = false;

  MusicTrack? _currentTrack; // желаемая дорожка
  MusicTrack? _startedTrack; // реально запущенная в bgm-плеере
  int _duckGen = 0;

  bool get muted => _muted;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  /// Громкость музыки с учётом мьюта (0 — глушим).
  double get _liveMusicVolume => _muted ? 0.0 : _musicVolume;

  // ── Инициализация (вызывать из main() после GameStorage.init()) ────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final s = GameStorage.instance;
    _muted = s.audioMuted;
    _musicVolume = s.audioMusicVolume;
    _sfxVolume = s.audioSfxVolume;
    await _safeAwait(() async {
      await FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([
        ..._musicFiles.values,
        ..._sfxSpecs.values.map((e) => e.file),
      ]);
    });
  }

  // ── Музыка ──────────────────────────────────────────────────────────────────
  /// Запустить/переключить фоновую дорожку (зациклена). Идемпотентно: повторный
  /// вызов с той же дорожкой не перезапускает её.
  void playMusic(MusicTrack track) {
    _currentTrack = track;
    _applyMusic();
  }

  void stopMusic() {
    _currentTrack = null;
    _startedTrack = null;
    _safe(() => FlameAudio.bgm.stop());
  }

  /// Пауза/возобновление музыки (для паузы партии). Не меняет выбранную
  /// дорожку — после [resumeMusic] продолжит с того же места.
  void pauseMusic() => _safe(() => FlameAudio.bgm.pause());
  void resumeMusic() => _safe(() => FlameAudio.bgm.resume());

  /// Кратко приглушить музыку под звуковой акцент (волна зачищена, босс пал) —
  /// чтобы стингер «пробил» микс. По истечении [holdMs] громкость вернётся,
  /// если за это время не запросили новый дак.
  void duckMusic({double factor = 0.3, int holdMs = 1300}) {
    if (_startedTrack == null) return;
    final gen = ++_duckGen;
    _safe(() async {
      await FlameAudio.bgm.audioPlayer.setVolume(_liveMusicVolume * factor);
      await Future<void>.delayed(Duration(milliseconds: holdMs));
      if (gen == _duckGen) {
        await FlameAudio.bgm.audioPlayer.setVolume(_liveMusicVolume);
      }
    });
  }

  /// Привести bgm-плеер к текущему желаемому состоянию (дорожка + громкость +
  /// мьют). Запускает дорожку только если её ещё нет; при изменении громкости
  /// той же дорожки — лишь меняет уровень, не перезапуская трек.
  void _applyMusic() {
    final t = _currentTrack;
    if (t == null) return;
    if (_liveMusicVolume <= 0) {
      if (_startedTrack != null) {
        _startedTrack = null;
        _safe(() => FlameAudio.bgm.stop());
      }
      return;
    }
    if (_startedTrack == t) {
      _safe(() => FlameAudio.bgm.audioPlayer.setVolume(_liveMusicVolume));
      return;
    }
    _startedTrack = t;
    _safe(() => FlameAudio.bgm.play(_musicFiles[t]!, volume: _liveMusicVolume));
  }

  // ── SFX ──────────────────────────────────────────────────────────────────────
  /// Сыграть короткий эффект. Дёргается из Flame-слоя на исходы `TankStep`.
  void play(SfxEvent event) {
    if (_muted || _sfxVolume <= 0) return;
    final spec = _sfxSpecs[event]!;
    final vol = (spec.gain * _sfxVolume).clamp(0.0, 1.0);
    _safe(() => FlameAudio.play(spec.file, volume: vol));
  }

  // ── Настройки (персист в GameStorage) ──────────────────────────────────────
  Future<void> setMuted(bool value) async {
    _muted = value;
    await GameStorage.instance.setAudioMuted(value);
    _applyMusic();
  }

  Future<void> setMusicVolume(double value) async {
    _musicVolume = value.clamp(0.0, 1.0);
    await GameStorage.instance.setAudioMusicVolume(_musicVolume);
    _applyMusic();
  }

  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value.clamp(0.0, 1.0);
    await GameStorage.instance.setAudioSfxVolume(_sfxVolume);
  }

  // ── Безопасное исполнение ───────────────────────────────────────────────────
  /// Запускает [op] «в фоне», глуша любые ошибки (нет файла / нет платформы).
  /// Под тестами — полный no-op (не трогаем `FlameAudio`).
  void _safe(FutureOr<void> Function() op) {
    if (_inTest) return;
    () async {
      try {
        await op();
      } catch (_) {
        // Клипа ещё нет в assets/audio/ или платформа недоступна — молчим.
      }
    }();
  }

  Future<void> _safeAwait(Future<void> Function() op) async {
    if (_inTest) return;
    try {
      await op();
    } catch (_) {
      // см. _safe
    }
  }
}
