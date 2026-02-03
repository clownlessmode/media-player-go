# Медиа-плеер Orange Pi

Минимальный клиент для Orange Pi: чек-ин по MAC каждые 10 минут, JWT, запрос медиа по `GET /api/device/me/media`, загрузка по `id`, воспроизведение через mplayer. Синхронизация при первом получении токена и в 4:00.

## Поведение

1. **Чек-ин каждые 10 минут** (процесс не завершается при 401):

   - `POST /api/device/check-in`, тело: `{ "macAddress": "AA:BB:CC:DD:EE:FF" }`
   - **401** — устройство ожидает назначения группы, в stderr пишется сообщение, цикл продолжается.
   - **200** — в теле `{ "accessToken": "<jwt>" }`, токен сохраняется в `.jwt`.

2. **После получения токена** и **в 4:00 ночи** (или после перезагрузки):
   - `GET /api/device/me/media` с заголовком `Authorization: Bearer <jwt>`;
   - ответ — JSON-массив объектов `[{ "id": "...", "url": "...", "name": "..." }]`;
   - **сначала** удаляются из `MEDIA_DIR` файлы, которых нет в новом списке (по `id`);
   - **затем** докачиваются все медиа по ссылкам; имена файлов — по `id` (как в ссылках);
   - когда всё скачано — запускается бесконечное воспроизведение папки через mplayer (`-vo fbdev2 -vf scale=1280:720` и т.д.).

## Переменные окружения

| Переменная             | По умолчанию            | Описание                                                                     |
| ---------------------- | ----------------------- | ---------------------------------------------------------------------------- |
| `SERVER_URL`           | `http://localhost:3000` | Базовый URL админки без слэша в конце                                        |
| `MEDIA_DIR`            | `./media`               | Папка для видео                                                              |
| `MPLAYER_AUDIO_DEVICE` | `plughw:1,0`            | ALSA-устройство для звука (часто 1 = HDMI). Список карт: `aplay -l`          |
| `MPLAYER_VO`           | авто                    | Вывод видео: при DISPLAY/WAYLAND — `x11`, иначе `fbdev2`. Можно задать явно. |

## Сборка

```bash
go build -o mediaplayer .
```

С подстановкой версии/коммита:

```bash
VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")
go build -ldflags "-X main.Version=$VERSION" -o mediaplayer .
```

## Запуск на Orange Pi

Установи mplayer и ffmpeg:

```bash
sudo apt install mplayer ffmpeg
```

Воспроизведение идёт через **ffmpeg concat → mplayer** (один поток без пауз между роликами). Если на переходе между двумя роликами экран кратко «зависает», скорее всего второй ролик не начинается с ключевого кадра (I-frame). Перекодируй его так, чтобы первый кадр был ключевым, например: `ffmpeg -i input.mp4 -c copy -force_key_frames "expr:eq(n,0)" output.mp4`.

Запуск (например, через systemd при включении):

```bash
export SERVER_URL=https://your-admin.example.com
./mediaplayer
```

## API сервера (ожидаемое)

- **POST /api/device/check-in**  
  Тело: `{"macAddress":"AA:BB:CC:DD:EE:FF"}`

  - 401 — устройство ожидает назначения группы;
  - 200 — в теле `{"accessToken":"<jwt>"}`.

- **GET /api/device/me/media**  
  Заголовок: `Authorization: Bearer <jwt>`
  - 200 — тело JSON: массив объектов `[{ "id": "string", "url": "string", "name": "string" }]`.
  - 401 — токен невалиден или устройство не найдено.
