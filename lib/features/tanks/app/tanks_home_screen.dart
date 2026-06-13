import 'package:flutter/material.dart';

import '../../../core/audio/audio_manager.dart';
import '../../../core/legal/legal_screens.dart';
import '../../../core/storage/game_storage.dart';
import '../logic/daily_level.dart';
import '../logic/level_model.dart';
import '../logic/survival.dart';
import 'tanks_campaign_screen.dart';
import 'tanks_game_screen.dart';
import 'tanks_settings_screen.dart';

/// Домашняя витрина «Танчиков»: выбор режима + настройки/документы.
class TanksHomeScreen extends StatefulWidget {
  const TanksHomeScreen({super.key});

  @override
  State<TanksHomeScreen> createState() => _TanksHomeScreenState();
}

class _TanksHomeScreenState extends State<TanksHomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioManager.instance.playMusic(MusicTrack.menu);
  }

  Future<void> _go(Widget screen) async {
    AudioManager.instance.play(SfxEvent.uiTap);
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (!mounted) return;
    AudioManager.instance.playMusic(MusicTrack.menu); // вернулись — снова меню
    setState(() {}); // обновить стрик/дейли/звёзды по возвращении
  }

  @override
  Widget build(BuildContext context) {
    final s = GameStorage.instance;
    final dailyDone = s.dailyDone(DateTime.now());
    final streak = s.streak;

    return Scaffold(
      backgroundColor: const Color(0xFF07051A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🪖',
                  style: TextStyle(fontSize: 54), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text('Танчики',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF1F0FF),
                  )),
              const Text('NATSUKASHI YORU',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 4,
                      color: Color(0xFF7060A0))),
              if (streak > 0) ...[
                const SizedBox(height: 10),
                Text('🔥 серия дней: $streak',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFFB454), fontSize: 13)),
              ],
              const Spacer(),
              _MenuButton(
                icon: Icons.flag_rounded,
                label: 'Кампания',
                subtitle: 'Мир «Двор» · 6 уровней',
                accent: const Color(0xFF4ECDC4),
                onTap: () => _go(const TanksCampaignScreen()),
              ),
              const SizedBox(height: 12),
              _MenuButton(
                icon: Icons.whatshot_rounded,
                label: 'Выживание',
                subtitle: 'Бесконечные волны · рекорд',
                accent: const Color(0xFFFF6FAE),
                onTap: () => _go(TanksGameScreen(
                  title: 'Выживание',
                  subtitle: 'Держись как можно дольше • защити базу',
                  mode: TanksMode.survival,
                  theme: TerrainTheme.proving,
                  build: buildSurvival,
                )),
              ),
              const SizedBox(height: 12),
              _MenuButton(
                icon: Icons.today_rounded,
                label: 'Вызов дня',
                subtitle: dailyDone ? 'сегодня пройден ✓' : 'один расклад на всех',
                accent: const Color(0xFFFFD54F),
                onTap: () {
                  final today = DateTime.now();
                  _go(TanksGameScreen(
                    title: 'Вызов дня',
                    subtitle: 'Один расклад на всех • раз в день',
                    mode: TanksMode.daily,
                    theme: TerrainTheme.courtyard,
                    build: () => buildDaily(today),
                  ));
                },
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _SmallButton(
                      icon: Icons.settings_rounded,
                      label: 'Настройки',
                      onTap: () => _go(const TanksSettingsScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallButton(
                      icon: Icons.description_outlined,
                      label: 'Документы',
                      onTap: () => _go(const DocsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x12FFFFFF),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF1F0FF),
                        )),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xFF8E7FBF))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x12FFFFFF),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFA78BFA), size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFFD8D0F5))),
            ],
          ),
        ),
      ),
    );
  }
}
