#!/bin/bash
# Pre-install script: проверка зависимостей и загрузка media-player-go
# Запуск: ./preinstall.sh   (при необходимости: sudo ./preinstall.sh)

set -e

REPO_RAW="https://raw.githubusercontent.com/clownlessmode/media-player-go/main"
SETUP_NAME="setup"
INSTALL_DIR="${INSTALL_DIR:-/tmp/media-player-go-install}"

# --- Определение менеджера пакетов ---
detect_pkg_manager() {
	if command -v apt-get &>/dev/null; then
		PKG_MGR="apt"
		PKG_UPDATE="apt-get update -qq"
		PKG_INSTALL="apt-get install -y"
	elif command -v dnf &>/dev/null; then
		PKG_MGR="dnf"
		PKG_UPDATE="dnf check-update -q || true"
		PKG_INSTALL="dnf install -y"
	elif command -v yum &>/dev/null; then
		PKG_MGR="yum"
		PKG_UPDATE="yum check-update -q || true"
		PKG_INSTALL="yum install -y"
	elif command -v apk &>/dev/null; then
		PKG_MGR="apk"
		PKG_UPDATE="apk update"
		PKG_INSTALL="apk add"
	else
		echo "Не найден подходящий менеджер пакетов (apt/dnf/yum/apk)."
		exit 1
	fi
}

# --- Установка пакета при отсутствии ---
ensure_installed() {
	local name="$1"
	local pkg="${2:-$1}"
	if command -v "$name" &>/dev/null; then
		echo "[OK] $name уже установлен: $(command -v "$name")"
		return 0
	fi
	echo "[...] Устанавливаю $name..."
	case "$PKG_MGR" in
		apt|dnf|yum)
			$PKG_UPDATE
			$PKG_INSTALL $pkg
			;;
		apk)
			$PKG_INSTALL $pkg
			;;
		*)
			echo "Установите $name вручную."
			exit 1
			;;
	esac
	echo "[OK] $name установлен."
}

# --- Скачивание файла ---
download() {
	local url="$1"
	local out="$2"
	if command -v curl &>/dev/null; then
		curl -fsSL "$url" -o "$out" || { rm -f "$out"; return 1; }
	elif command -v wget &>/dev/null; then
		wget -q -O "$out" "$url" || { rm -f "$out"; return 1; }
	else
		echo "Нужен curl или wget для загрузки."
		exit 1
	fi
}

# --- main ---
echo "=== Pre-install: media-player-go ==="
detect_pkg_manager

ensure_installed "git" "git"
ensure_installed "ffmpeg" "ffmpeg"
ensure_installed "mplayer" "mplayer"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "[...] Загружаю $SETUP_NAME..."
if download "$REPO_RAW/$SETUP_NAME" "$SETUP_NAME"; then
	chmod +x "$SETUP_NAME"
	echo "[OK] $SETUP_NAME загружен."
else
	echo "[FAIL] Не удалось загрузить $SETUP_NAME с $REPO_RAW/$SETUP_NAME"
	exit 1
fi

echo "[...] Запускаю setup с sudo..."
sudo ./"$SETUP_NAME"
echo "=== Готово ==="
