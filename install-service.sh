#!/bin/bash
# Один раз запустить с sudo (введёте пароль). После этого плеер будет автоматически стартовать при каждой загрузке.
# Запуск: sudo ./install-service.sh

set -e
cd "$(dirname "$0")"
INSTALL_DIR="$(pwd -P)"
BINARY="$INSTALL_DIR/mediaplayer-linux-arm64"
SERVICE_FILE="$INSTALL_DIR/mediaplayer.service"

if [ ! -f "$BINARY" ]; then
  echo "Ошибка: не найден $BINARY (соберите для ARM: ./build-orangepi.sh arm64)"
  exit 1
fi
if [ ! -f "$SERVICE_FILE" ]; then
  echo "Ошибка: не найден $SERVICE_FILE"
  exit 1
fi

# Подставляем реальный путь в unit и копируем в systemd
sed "s|/root/media-player-go|$INSTALL_DIR|g" "$SERVICE_FILE" > /etc/systemd/system/mediaplayer.service
systemctl daemon-reload
systemctl enable mediaplayer
systemctl start mediaplayer

echo "Готово. Медиа-плеер включён и запущен. При каждой загрузке будет стартовать автоматически (без пароля)."
echo "Логи: journalctl -u mediaplayer -f"
