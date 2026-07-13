#!/bin/bash
# Скрипт автоматической сборки AuraGit OS (на базе AOSP Android 14)[cite: 2]

echo "=== СБОРКА AURAGIT OS ==="[cite: 2]
set -e[cite: 2]

# Шаг 1: Создание рабочего окружения[cite: 2]
WORK_DIR="$HOME/auragit_build"[cite: 2]
mkdir -p "$WORK_DIR"[cite: 2]
cd "$WORK_DIR"[cite: 2]

# Шаг 2: Инициализация репозитория Android 14[cite: 2]
if [ ! -d ".repo" ]; then[cite: 2]
    echo "[1/5] Инициализация исходного кода AOSP..."[cite: 2]
    repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r1 --depth=1[cite: 2]
fi[cite: 2]

# Шаг 3: Накатывание манифеста AuraGit OS[cite: 2]
echo "[2/5] Синхронизация манифестов AuraGit..."[cite: 2]
mkdir -p .repo/local_manifests[cite: 2]

cat <<EOF > .repo/local_manifests/auragit.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <!-- Удаляем стандартные репозитории настроек и ядра AOSP -->
  <remove-project name="platform/packages/apps/Settings" />
  <remove-project name="platform/frameworks/base" />

  <!-- Подключаем кастомные репозитории AuraGit OS -->
  <project path="packages/apps/Settings" 
           name="AuraGitOS/packages_apps_Settings" 
           revision="aura-14.0" 
           remote="github" />

  <project path="frameworks/base" 
           name="AuraGitOS/frameworks_base" 
           revision="aura-14.0" 
           remote="github" />

  <!-- Добавляем наш системный демон управления состояниями -->
  <project path="system/core/auragitd" 
           name="AuraGitOS/system_core_auragitd" 
           revision="main" 
           remote="github" />
</manifest>
EOF

# Синхронизируем код[cite: 2]
repo sync -c -j$(nproc) --force-sync[cite: 2]

# Шаг 4: Компиляция нашего системного демона на Rust[cite: 2]
echo "[3/5] Компиляция демона ядра auragitd..."[cite: 2]
cd system/core/auragitd[cite: 2]
mmma .[cite: 2]
cd "$WORK_DIR"[cite: 2]

# Шаг 5: Запуск компиляции всей операционной системы[cite: 2]
echo "[4/5] Подготовка переменных окружения Android..."[cite: 2]
source build/envsetup.sh[cite: 2]

lunch aosp_car_x86_64-userdebug[cite: 2]

echo "[5/5] Запуск компиляции AuraGit OS..."[cite: 2]
m -j$(nproc)[cite: 2]

echo "============================================="[cite: 2]
echo "СБОРКА ЗАВЕРШЕНА!"[cite: 2]
echo "============================================="[cite: 2]
