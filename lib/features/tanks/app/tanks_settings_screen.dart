import 'package:flutter/material.dart';

import '../../../core/audio/audio_manager.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/storage/game_storage.dart';

/// Настройки: звук (общий мьют + громкость музыки/эффектов) и вибрация.
class TanksSettingsScreen extends StatefulWidget {
  const TanksSettingsScreen({super.key});

  @override
  State<TanksSettingsScreen> createState() => _TanksSettingsScreenState();
}

class _TanksSettingsScreenState extends State<TanksSettingsScreen> {
  final _audio = AudioManager.instance;
  late bool _haptics = GameStorage.instance.hapticsOn;
  late bool _muted = _audio.muted;
  late double _music = _audio.musicVolume;
  late double _sfx = _audio.sfxVolume;

  void _setHaptics(bool on) {
    setState(() => _haptics = on);
    Haptics.enabled = on;
    GameStorage.instance.setHaptics(on);
  }

  void _setMuted(bool soundOn) {
    setState(() => _muted = !soundOn);
    _audio.setMuted(!soundOn);
  }

  void _setMusic(double v) {
    setState(() => _music = v);
    _audio.setMusicVolume(v);
  }

  void _setSfx(double v) {
    setState(() => _sfx = v);
    _audio.setSfxVolume(v);
  }

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFFF1F0FF);
    const sub = Color(0xFF7060A0);
    const accent = Color(0xFF4ECDC4);
    return Scaffold(
      backgroundColor: const Color(0xFF07051A),
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SwitchListTile(
            value: !_muted,
            onChanged: _setMuted,
            title: const Text('Звук', style: TextStyle(color: text)),
            subtitle:
                const Text('Музыка и эффекты', style: TextStyle(color: sub)),
          ),
          _VolumeTile(
            icon: Icons.music_note_rounded,
            label: 'Музыка',
            value: _music,
            enabled: !_muted,
            accent: accent,
            onChanged: _setMusic,
          ),
          _VolumeTile(
            icon: Icons.graphic_eq_rounded,
            label: 'Эффекты',
            value: _sfx,
            enabled: !_muted,
            accent: accent,
            onChanged: _setSfx,
            // Дать услышать выбранный уровень на отпускании ползунка.
            onChangeEnd: (_) => _audio.play(SfxEvent.explosion),
          ),
          const Divider(height: 32, color: Color(0xFF1C1633)),
          SwitchListTile(
            value: _haptics,
            onChanged: _setHaptics,
            title: const Text('Вибрация', style: TextStyle(color: text)),
            subtitle: const Text('Тактильный отклик на попадания и взрывы',
                style: TextStyle(color: sub)),
          ),
        ],
      ),
    );
  }
}

/// Строка с иконкой, подписью, слайдером 0..1 и процентом справа.
class _VolumeTile extends StatelessWidget {
  const _VolumeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.accent,
    required this.onChanged,
    this.onChangeEnd,
  });

  final IconData icon;
  final String label;
  final double value;
  final bool enabled;
  final Color accent;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final tint = enabled ? const Color(0xFFD8D0F5) : const Color(0xFF4A4070);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(color: tint, fontSize: 14)),
          ),
          Expanded(
            child: Slider(
              value: value,
              activeColor: accent,
              inactiveColor: const Color(0xFF241B3E),
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? onChangeEnd : null,
            ),
          ),
          SizedBox(
            width: 38,
            child: Text('${(value * 100).round()}',
                textAlign: TextAlign.right,
                style: TextStyle(color: tint, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
