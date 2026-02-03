#!/bin/bash
# Сборка медиа-плеера для Orange Pi (Armbian, Linux ARM)
# Использование:
#   ./build-orangepi.sh           — собрать для arm64 (Orange Pi 3/4/5 и т.д.)
#   ./build-orangepi.sh arm64     — то же
#   ./build-orangepi.sh arm       — собрать для armv7 (Orange Pi Zero, One, PC)

set -e
cd "$(dirname "$0")"

ARCH="${1:-arm64}"
VERSION="${VERSION:-dev}"
BINARY="mediaplayer"

case "$ARCH" in
  arm64|aarch64)
    GOOS=linux GOARCH=arm64 go build -ldflags "-X main.Version=$VERSION" -o "${BINARY}-linux-arm64" .
    echo "Собран: ${BINARY}-linux-arm64 (linux/arm64)"
    ;;
  arm|armv7|armhf)
    GOOS=linux GOARCH=arm GOARM=7 go build -ldflags "-X main.Version=$VERSION" -o "${BINARY}-linux-arm" .
    echo "Собран: ${BINARY}-linux-arm (linux/arm/v7)"
    ;;
  *)
    echo "Неизвестная архитектура: $ARCH"
    echo "Допустимо: arm64, arm"
    exit 1
    ;;
esac
