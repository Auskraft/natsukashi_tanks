# AUDIO.md — звук «Танчиков» (Фаза 6)

> Манифест аудио-клипов + где взять бесплатно (CC0). **Имена файлов в этом
> документе — контракт** с `lib/core/audio/audio_manager.dart`. Положи клипы в
> `assets/audio/` ровно под этими именами — код уже всё разводит.

## Как это устроено
- Вся логика звука — в `AudioManager` (`lib/core/audio/audio_manager.dart`):
  музыка (loop через `FlameAudio.bgm`), короткие SFX (`FlameAudio.play`,
  low-latency), **дакинг** (приглушение музыки под акцент), громкость музыки/
  эффектов и общий мьют (персист в `GameStorage`), прелоад кэша.
- **Пока файлов нет — тишина, не падение.** Любое обращение к отсутствующему
  клипу глушится (try/catch + гард `FLUTTER_TEST`). Можно выкатывать **любым
  подмножеством**: нет файла → молчит только его событие, остальное звучит.
- Папка `assets/audio/` уже объявлена в `pubspec.yaml` как директория. Кладёшь
  файлы → `flutter pub get` → перезапуск. **Править pubspec под каждый файл не
  нужно.**

## Технический формат (рекомендация)
| Параметр | Музыка | SFX |
|---|---|---|
| Контейнер/кодек | **OGG Vorbis** (`.ogg`) | **OGG Vorbis** (`.ogg`) |
| Каналы | стерео | моно (меньше размер, для SFX норм) |
| Частота | 44.1 кГц | 44.1 кГц |
| Качество | VBR ~q5 (~160 kbps) | VBR ~q3–4 |
| Длина | бесшовный луп 30–90 с | 0.1–1.0 с (стингеры до ~2–3 с) |
| Громкость | нормализуй к ~ −16 LUFS (фон под SFX) | пик ~ −3 dBFS |

- **Почему OGG, а не MP3:** у MP3 при зацикливании появляется пауза (encoder
  delay) → луп «дёргается». OGG через `loop` (`ReleaseMode.loop`) циклит
  бесшовно. Для SFX OGG тоже ок (есть прелоад + low-latency плеер).
- **Альтернатива для SFX:** WAV (PCM 16-bit) даёт минимальную задержку, но
  крупнее. OGG достаточно.
- Относительный микс между событиями уже задан в коде (колонка «gain» ниже) —
  тебе достаточно нормализовать каждый файл к ровному пику, баланс сделает код.
- **Бюджет размера:** держи суммарно < ~3–5 МБ (с OGG это легко) — APK маленький.

## Конвертация
- **Audacity:** `File → Export → Export as OGG` (Quality ~5). Моно для SFX:
  `Tracks → Mix → Stereo to Mono`.
- **ffmpeg:** `ffmpeg -i вход.wav -ac 1 -c:a libvorbis -q:a 4 sfx_xxx.ogg`
  (для музыки убери `-ac 1`, поставь `-q:a 5`).

---

## Манифест: музыка (3 файла, зациклены)
| Файл | Когда играет | Характер |
|---|---|---|
| `music_menu.ogg` | витрина, экран «Готов», возврат в меню | спокойный/атмосферный луп |
| `music_battle.ogg` | обычный бой (кампания/выживание/вызов дня) | драйвовый, ритмичный |
| `music_boss.ogg` | бой с боссом (вкл. при появлении босса) | напряжённый, тяжёлый |

> Победа/поражение музыкой не глушат поверх — на них играют **стингеры**
> `sfx_victory` / `sfx_gameover`, а музыка боя в этот момент останавливается.

## Манифест: SFX (17 файлов)
`gain` — базовый микс в коде (×общую громкость SFX). Менять не нужно — просто
нормализуй файл.

| Файл | gain | Когда играет | Заметки по подбору |
|---|---|---|---|
| `sfx_shoot_player.ogg` | 0.55 | выстрел игрока | звонкий «пиу», короткий |
| `sfx_shoot_enemy.ogg` | 0.38 | выстрел врага | глуше/тише выстрела игрока |
| `sfx_brick.ogg` | 0.55 | скол кирпича пулей | сухой «тук»/крошка |
| `sfx_steel.ogg` | 0.55 | рикошет от стали | металлический «дзынь» |
| `sfx_clash.ogg` | 0.60 | пуля попала в пулю | короткий щелчок/искра |
| `sfx_explosion.ogg` | 0.85 | взрыв танка | главный «бум» (частый) |
| `sfx_explosion_big.ogg` | 1.00 | взрыв **босса** | мощнее/длиннее обычного |
| `sfx_spawn.ogg` | 0.50 | появление врага | «варп»/материализация |
| `sfx_powerup_appear.ogg` | 0.50 | бонус возник на поле | мягкий «блимп» |
| `sfx_powerup.ogg` | 0.80 | подбор бонуса | приятный «пик-ап» |
| `sfx_upgrade.ogg` | 0.85 | апгрейд танка (звезда подняла тир) | восходящий аккорд |
| `sfx_player_hit.ogg` | 0.90 | игрок подбит | резкий удар/«дамаг» |
| `sfx_base_alarm.ogg` | 0.85 | попадание по базе-орлу | тревожный сигнал |
| `sfx_wave_clear.ogg` | 0.90 | волна зачищена | короткая победная фраза |
| `sfx_victory.ogg` | 1.00 | победа в партии | стингер-фанфара (~2–3 с) |
| `sfx_gameover.ogg` | 1.00 | поражение | нисходящий стингер |
| `sfx_ui_tap.ogg` | 0.55 | тап по кнопке меню | тихий мягкий клик |

### Минимальный набор (если хочется выкатить быстро)
Достаточно для «ощущения звука», остальное добавишь позже:
`music_menu`, `music_battle`, `sfx_shoot_player`, `sfx_explosion`, `sfx_brick`,
`sfx_player_hit`, `sfx_base_alarm`, `sfx_wave_clear`, `sfx_victory`,
`sfx_gameover`, `sfx_ui_tap` (11 файлов).

---

## Где взять бесплатно (CC0 и аналоги)

### 🎛️ Самый быстрый путь для SFX — сгенерировать самому
Ретро-эффекты «Танчиков» (выстрел/взрыв/пикап/апгрейд/хит) проще всего
**сгенерировать** — звук аутентичный для Battle City, и результат полностью твой
(лицензий нет вообще):
- **jsfxr** — <https://sfxr.me> (прямо в браузере; пресеты Shoot/Explosion/
  Pickup/Hit/Powerup → Export WAV → конвертни в OGG). **Рекомендую для всех
  `sfx_shoot_*`, `sfx_powerup*`, `sfx_upgrade`, `sfx_spawn`, `sfx_clash`.**
- **Bfxr** — <https://www.bfxr.net> (десктоп/веб, мощнее jsfxr).
- **ChipTone** (SFBGames) — ещё один генератор, удобные пресеты.

### 🔊 Готовые SFX-библиотеки
- **Kenney** — CC0, **без атрибуции, коммерция OK** (всё public domain):
  - Impact Sounds (удары/взрывы): <https://kenney.nl/assets/impact-sounds>
  - Digital Audio (ретро-биперы/пикапы): <https://kenney.nl/assets/digital-audio>
  - UI Audio (клики кнопок → `sfx_ui_tap`): <https://kenney.nl/assets/ui-audio>
  - Interface Sounds: <https://kenney.nl/assets/interface-sounds>
  - Вся аудио-категория: <https://kenney.nl/assets/category:Audio>
- **Freesound** — <https://freesound.org> — в фильтрах слева выбери
  **License → «Creative Commons 0»**. Хорош для «сырых» звуков (металл/сталь,
  вода, сигнал тревоги для базы). Нужен бесплатный аккаунт.
- **Pixabay Sound Effects** — <https://pixabay.com/sound-effects/> —
  Pixabay License (см. оговорку ниже).

### 🎵 Музыкальные лупы
- **OpenGameArt** (фильтруй **License = CC0**, тег `chiptune`/`loop`):
  - CC0 Music: <https://opengameart.org/content/cc0-music-0>
  - CC0 Retro Music: <https://opengameart.org/content/cc0-retro-music>
  - CC0 8-bit/Chiptune: <https://opengameart.org/content/audio-cc0-8bit-chiptune>
  - 8-bit Epic Space Shooter Music: <https://opengameart.org/content/8-bit-epic-space-shooter-music>
- **FreePD** — <https://freepd.com> — public domain (CC0) музыка по категориям
  (Action/Electronic → `music_battle`/`music_boss`; спокойное → `music_menu`).
- **Pixabay Music** — <https://pixabay.com/music/> — ищи `arcade`, `chiptune`,
  `8-bit`, `loop` (Pixabay License, см. ниже).
- **Patrick de Arteaga** — <https://patrickdearteaga.com> — royalty-free
  чиптюн, отличный ретро-фит (атрибуция приветствуется, но не обязательна).

### Рекомендованный маппинг «файл → источник»
- `sfx_shoot_*`, `sfx_powerup*`, `sfx_upgrade`, `sfx_spawn`, `sfx_clash` →
  **jsfxr/Bfxr** (генерация).
- `sfx_explosion`, `sfx_explosion_big`, `sfx_player_hit` → **Kenney Impact
  Sounds** (или jsfxr Explosion).
- `sfx_brick`, `sfx_steel`, `sfx_base_alarm` → **Freesound (CC0)** или Kenney.
- `sfx_ui_tap` → **Kenney UI Audio**.
- `sfx_wave_clear`, `sfx_victory`, `sfx_gameover` → **Kenney Digital Audio**
  (джинглы) или короткий чиптюн с OpenGameArt CC0.
- `music_menu/battle/boss` → **OpenGameArt CC0 / FreePD / Pixabay**.

---

## ⚠️ Лицензионная гигиена (важно для RuStore-модерации)
- **CC0** — публичное достояние, атрибуция не требуется. Идеал.
- **Pixabay License** — тоже **без обязательной атрибуции и можно коммерчески**,
  но это **не CC0**: нельзя перепродавать сами файлы «как есть»; для встраивания
  в приложение — ок. (Подтверждено в FAQ Pixabay.)
- **НЕ бери:** incompetech/Kevin MacLeod (это **CC-BY** — нужна атрибуция);
  что-либо с пометкой *non-commercial* / *no derivatives*; звуки/музыку,
  выдранные из чужих игр/фильмов.
- **Всё равно веди файл `assets/audio/CREDITS.md`** (источник + автор + лицензия
  + ссылка на каждый клип). Для CC0 не обязательно, но при модерации и на будущее
  крайне упрощает жизнь.

## Как добавить файлы (чек-лист)
1. Сконвертируй в `.ogg` (см. «Конвертация»).
2. Назови **точно** как в манифесте (регистр важен), положи в `assets/audio/`.
3. `flutter pub get`.
4. Перезапусти приложение (`flutter run` / пересборка) — звук заиграет сам.
5. Громкость/мьют — в экране «Настройки»; per-event баланс — в `_sfxSpecs`
   (`audio_manager.dart`), если захочешь подкрутить.
