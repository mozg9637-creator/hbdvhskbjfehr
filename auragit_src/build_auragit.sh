#!/bin/bash
# Скрипт автоматической сборки AuraGit OS (на базе AOSP Android 14)

echo "=== СБОРКА AURAGIT OS ==="
set -e

# Шаг 1: Создание рабочего окружения
WORK_DIR="$HOME/auragit_build"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Шаг 2: Инициализация репозитория Android 14
if [ ! -d ".repo" ]; then
    echo "[1/5] Инициализация исходного кода AOSP..."
    repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r1 --depth=1
fi

# Шаг 3: Накатывание манифеста AuraGit OS
echo "[2/5] Синхронизация манифестов AuraGit..."
mkdir -p .repo/local_manifests
cat <<EOF > .repo/local_manifests/auragit.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remove-project name="platform/packages/apps/Settings" />
  <!-- Сюда вставляются наши кастомные репозитории из Шага 1 -->
</manifest>
EOF

# Синхронизируем код (загрузка ~100 ГБ)
repo sync -c -j$(nproc) --force-sync

# Шаг 4: Компиляция нашего системного демона на Rust
echo "[3/5] Компиляция демона ядра auragitd..."
cd system/core/auragitd
# Используем встроенный в Android компилятор Rust (Soong)
mmma . 
cd "$WORK_DIR"

# Шаг 5: Запуск компиляции всей операционной системы
echo "[4/5] Подготовка переменных окружения Android..."
source build/envsetup.sh

# Выбираем устройство (например, эмулятор x86_64 для тестирования на ПК)
lunch aosp_car_x86_64-userdebug

echo "[5/5] Запуск компиляции AuraGit OS (это может занять несколько часов)..."
m -j$(nproc)

echo "============================================="
echo "СБОРКА ЗАВЕРШЕНА!"
echo "Образ системы лежит в: out/target/product/generic_x86_64/system.img"
echo "Вы можете запустить его в эмуляторе: emulator"
echo "============================================="
