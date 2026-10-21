# Сторонние компоненты и лицензии

Приложение использует следующие сторонние компоненты. Перед публикацией сборки проверь актуальные версии лицензий в `pubspec.lock` и в каталоге пакетов.

## Stockfish 19 / multistockfish

- `multistockfish` — Flutter-плагин lichess.org, лицензия **GPL-3.0**.
- В приложение встраивается Stockfish 19 (с лёгкой NNUE) через `multistockfish_light`.
- Stockfish распространяется по **GPL-3.0**. Если ты распространяешь APK с этим движком, нужно соблюсти GPL: предоставить получателям соответствующий исходный код (или письменное предложение предоставить его) и сохранить уведомления об авторских правах.
- Исходный код движка и плагина: <https://github.com/lichess-org/dart-multistockfish>, <https://github.com/official-stockfish/Stockfish>.

## advanced_chess_board

- Лицензия **BSD-2-Clause**.
- Пакет поставляет изображения фигур, полученные с Chess.com. Код пакета и ассеты могут иметь разные условия; при коммерческой публикации проверь права на изображения отдельно.
- Репозиторий: <https://github.com/mkvmb6/advanced_chess_board>.

## chess.dart

- Лицензия **BSD-2-Clause / MIT**.
- Репозиторий: <https://github.com/davecom/chess.dart>.

## Flutter/Dart, sqflite, provider, shared_preferences, audioplayers

- Flutter и Dart — BSD-3-Clause.
- `sqflite` — BSD-2-Clause.
- `provider` — MIT.
- `shared_preferences` — BSD-3-Clause.
- `audioplayers` — MIT.
- Актуальные тексты лицензий находятся в `.pub-cache` / `pubspec.lock` соответствующих версий.

## Звуки и иконка

- WAV-файлы `assets/sounds/*.wav` сгенерированы специально для проекта скриптом `tool/generate_sounds.py`.
- Лаунчер-иконка сгенерирована скриптом `tool/generate_icon.py` с использованием системного шрифта Segoe UI Symbol; для распространения замени шрифтовой глиф на собственный SVG/PNG, если этого требует выбранная лицензия шрифта.

## Шрифты

Приложение использует системный шрифт Android (Roboto) и не поставляет внешних шрифтовых файлов.
