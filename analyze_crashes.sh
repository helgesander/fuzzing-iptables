#!/bin/bash

# Проверка, что аргумент передан
if [ -z "$1" ]; then
    echo "Usage: $0 <crash_directory>"
    exit 1
fi

# Директория с крашами (передаётся как аргумент)
CRASH_DIR="$1"

# Программа для запуска
PROGRAM="/root/iptables/afl-install/sbin/iptables-restore"

# Проходим по всем файлам крашей
for crash_file in "$CRASH_DIR"/id:*; do
    echo "Processing crash file: $crash_file"
    echo "================================================================"

    # Запускаем программу с текущим файлом краша
    # Используем AddressSanitizer для получения подробной информации
    ASAN_OPTIONS=detect_leaks=0 $PROGRAM "$crash_file" 2>&1 | grep -E "ERROR:|WRITE of|READ of|#0 |#1 |#2 |#3 "

    echo "================================================================"
    echo ""
done
