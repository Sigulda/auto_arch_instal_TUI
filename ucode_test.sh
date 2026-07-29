#!/bin/bash

# Автоопределение процессора для выбора правильной строки initrd
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE_IMG="amd-ucode"
elif grep -q "GenuineIntel" /proc/cpuinfo; then
    UCODE_IMG="intel-ucode"
else
    # На случай виртуальных машин, чтобы не вызывать ошибку загрузчика
    UCODE_IMG=""
fi

echo "$UCODE_IMG"
