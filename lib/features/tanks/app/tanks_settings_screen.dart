import 'package:flutter/material.dart';

import '../../../core/feedback/haptics.dart';
import '../../../core/storage/game_storage.dart';

/// Настройки. Пока — вибрация (звук появится в фазе 6).
class TanksSettingsScreen extends StatefulWidget {
  const TanksSettingsScreen({super.key});

  @override
  State<TanksSettingsScreen> createState() => _TanksSettingsScreenState();
}

class _TanksSettingsScreenState extends State<TanksSettingsScreen> {
  late bool _haptics = GameStorage.instance.hapticsOn;

  void _setHaptics(bool on) {
    setState(() => _haptics = on);
    Haptics.enabled = on;
    GameStorage.instance.setHaptics(on);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07051A),
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF1F0FF),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SwitchListTile(
            value: _haptics,
            onChanged: _setHaptics,
            title: const Text('Вибрация',
                style: TextStyle(color: Color(0xFFF1F0FF))),
            subtitle: const Text('Тактильный отклик на попадания и взрывы',
                style: TextStyle(color: Color(0xFF7060A0))),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Text('🔊 Звук и музыка — в следующем обновлении.',
                style: TextStyle(color: Color(0xFF7060A0), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
