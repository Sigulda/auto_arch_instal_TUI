#!/bin/bash
#
# TUI лаунчер для установки арч линукс
#
# Цвета
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
#
# Скрыть курсор
hide_cursor() { tput civis; }
# Показать курсор
show_cursor() { tput cnorm; }
# Очистить экран
clear_screen() { clear; }
# типа загрузка
load_screen() {
    clear
    echo -e "   Проверка."
    sleep 0.5
    clear
    echo -e "   Проверка.."
    sleep 0.5
    clear
    echo -e "   Проверка..."
    sleep 0.5
    clear
    echo -e "   Проверка."
    sleep 0.5
    clear
    echo -e "   Проверка.."
    sleep 0.5
    clear
    echo -e "   Проверка..."
    sleep 0.5
    clear
}
# нажмите клавишу
press_screen() {
    echo -e "\n${DIM}Нажми клавишу...${NC}"
    read -n1 -s
}
# Вопрос согласия
yes_no_menu() {
    local title="${1:-Продолжить?}"
    local actions=("Да" "Нет" )
    local sel=0
    local tot=${#actions[@]}
    while true; do
        clear_screen
        hide_cursor
        echo -e "   ${title}"
        for i in "${!actions[@]}"; do
            if [ $i -eq $sel ]; then
                echo -e "  ${GREEN}▶ ${actions[$i]}${NC}"
            else
                echo -e "  ${DIM}    ${actions[$i]}${NC}"
            fi
        done

        read -rsn1 k
        case "$k" in
            "")
                case $sel in
                    0) # да
                        break ;;
                    1) # нет
                        main_menu ;;
                esac
                ;;
            j|J) ((sel++)) ;;
            k|K) ((sel--)) ;;
            $'\x1b')
                read -rsn2 -t 0.1 s
                [[ "$s" == "[A" ]] && ((sel--))
                [[ "$s" == "[B" ]] && ((sel++))
                ;;
        esac

        # Зацикливание
        (( sel < 0 )) && sel=$((tot - 1))
        (( sel >= tot )) && sel=0
    done
}
# Заголовок
show_header() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
***|    Добро пожаловать в установщик ARCH LINUX    |***
EOF
    echo -e "${NC}"
    sleep 2
}
# Основное меню установщика
main_menu() {
    local actions=("Проверка доступности интернета" "Настройка сети" "Создание разделов на диске" "установка Pacstrap" "Post install настройка системы" "Перезагрузка" "Выключение" "Выход")
    local sel=0
    local tot=${#actions[@]}

    while true; do
        clear_screen
        hide_cursor
        echo -e "   ------------------------------------"
        echo -e "   ---------| Главное меню |-----------"
        echo -e "   ------------------------------------"
        echo -e " "
        echo -e "${NC}"
        echo -e "Статус сети:"
        [[ -z "$PING_STATUS" ]] && echo -e "   ${YELLOW}Требуется проверка сети!" || echo -e "    $PING_STATUS"
        echo -e " "
        echo -e "${NC}"
        echo -e "Информация о диске"
        [[ -z "$DISK" ]] && echo -e "   ${YELLOW}диск не выбран" || echo -e "    выбран диск: ${GREEN}$DISK"
        echo -e "${NC}"
        echo -e " "
        for i in "${!actions[@]}"; do
            if [ $i -eq $sel ]; then
                echo -e "  ${GREEN}▶ ${actions[$i]}${NC}"
            else
                echo -e "  ${DIM}    ${actions[$i]}${NC}"
            fi
        done

        read -rsn1 k
        case "$k" in
            "")
                case $sel in
                    0) # Проверить соединение с интернетом
                        ping_arch ;;
                    1) # Настройка сети
                        network_creat ;;
                    2) # создание разделов на диске
                        disk_create ;;
                    3) # установка Pacstrap
                        pacstrap_start ;;
                    4) # Post install настройка системы
                        post_install ;;
                    5) # Перезагрузка
                        reboot_start ;;
                    6) # Выключение
                        poweroff_start ;;
                    7) # Выход
                        show_cursor
                        clear_screen
                        exit ;;
                esac
#                press_screen
                ;;
            j|J) ((sel++)) ;;
            k|K) ((sel--)) ;;
            $'\x1b')
                read -rsn2 -t 0.1 s
                [[ "$s" == "[A" ]] && ((sel--))
                [[ "$s" == "[B" ]] && ((sel++))
                ;;
        esac

        # Зацикливание
        (( sel < 0 )) && sel=$((tot - 1))
        (( sel >= tot )) && sel=0
    done
}

ping_arch() {
    clear
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}Есть соединение!${NC}"
        PING_STATUS="${GREEN}Есть соединение!${NC}"
    else
        echo -e "${RED}Нет соединения с интернетом!${NC}"
        PING_STATUS="${RED}Нет соединения с интернетом!${NC}"
        # Здесь мы не выходим из скрипта, а просто предупреждаем
    fi
    press_screen
}
# настройка сети
network_creat() {
    clear
    echo -e "Настройка сети (для вай-фай)"
    echo -e "   station list"
    echo -e "   station <ваш адаптер> scan"
    echo -e "   station <ваш адаптер> get-networks"
    echo -e "   station <ваш адаптер> connect <ваш Wi-Fi>"
    sleep 3
    show_cursor
    iwctl
    clear
    hide_cursor
    if ping -c 3 1.1.1.1 >/dev/null 2>&1; then
        echo -e "${GREEN}   Сеть успешно настроена!${NC}"
        PING_STATUS="${GREEN}Есть соединение!${NC}"
    else
        echo -e "${RED} Сеть всё ещё недоступна.${NC}"
        PING_STATUS="${RED}Нет соединения с интернетом!${NC}"
    fi
    press_screen
}
# меню выбора диска
disk_menu() {
    local selected=${selected:-0}
    while true; do
        # Собираем массив дисков dynamically
        local items=()
        while read -r name size model; do
            [[ -z "$name" || "$size" == "0B" ]] && continue
            items+=("$name ($size) - $model")
        done < <(lsblk -d -n -o NAME,SIZE,MODEL)
        # Добавляем пункт выхода в самый конец
        items+=("Назад")
        local total=${#items[@]}
        # Защита границ индекса
        (( selected >= total )) && selected=$((total - 1))
        (( selected < 0 )) && selected=0
        clear_screen
        echo -e "  ${BOLD}ВЫБОР ДИСКА (Доступно: $((total - 1)))${NC}\n"
        for i in "${!items[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "  ${GREEN}▶ ${items[$i]}${NC}"
            else
                echo -e "  ${DIM}    ${items[$i]}${NC}"
            fi
        done
        # Читаем один символ с клавиатуры
        read -rsn1 key
        case "$key" in
            "") # Нажатие Enter
                # Если выбран последний пункт ("Назад")
                if [ "$selected" -eq $((total - 1)) ]; then
                    SELECTED_DISK="" # Сбрасываем переменную, так как выбор отменен
                    main_menu
                    return 0
                else
                    # Записываем в переменную ТОЛЬКО имя диска (первое слово)
                    SELECTED_DISK=$(echo "${items[$selected]}" | awk '{print $1}')
                    break # Выходим из цикла меню
                fi
                ;;
            j|J) ((selected++)) ;;
            k|K) ((selected--)) ;;
            $'\x1b')
                read -rsn2 -t 0.1 seq
                [[ "$seq" == "[A" ]] && ((selected--))
                [[ "$seq" == "[B" ]] && ((selected++))
                ;;
            q|Q)
                SELECTED_DISK=""
                return 0
                ;;
        esac

        # Зацикливание выбора по кругу
        if (( selected < 0 )); then selected=$((total - 1)); fi
        if (( selected >= total )); then selected=0; fi
    done
    press_screen
}
# скрипт разметки тип sda
sda_disk_skript() {
    echo -e "используется скрипт установки для sda дисков"
    DISK=$SELECTED_DISK
    echo -e "Имя диска: ${GREEN}$DISK${NC}"
    echo -e "Размер SWAP: $SWAP"
    echo -e "Размер ROOT: $ROOT"
    echo -e "Размер HOME: остаток места"
    yes_no_menu
    # Чистим диск
    sgdisk --zap-all /dev/$DISK
    # Разметка
    parted /dev/$DISK mklabel gpt
    parted /dev/$DISK mkpart ESP fat32 1MiB 513MiB
    parted /dev/$DISK set 1 esp on
    parted /dev/$DISK mkpart primary linux-swap 513MiB $((513+${SWAP%G}*1024))MiB
    parted /dev/$DISK mkpart primary ext4 $((513+${SWAP%G}*1024))MiB $((513+${SWAP%G}*1024+${ROOT%G}*1024))MiB
    parted /dev/$DISK mkpart primary ext4 $((513+${SWAP%G}*1024+${ROOT%G}*1024))MiB 100%
    # Форматирование
    mkfs.fat -F32 /dev/${DISK}1
    mkswap /dev/${DISK}2
    mkfs.ext4 -F /dev/${DISK}3
    mkfs.ext4 -F /dev/${DISK}4
    # Монтирование
    mount /dev/${DISK}3 /mnt
    mkdir /mnt/{boot,home}
    mount /dev/${DISK}1 /mnt/boot
    mount /dev/${DISK}4 /mnt/home
    swapon /dev/${DISK}2
}
# скрипт разметки тип nvme
nvme_disk_skript() {
    echo -e "используется установка для nvme типов диска"
    DISK=$SELECTED_DISK
    echo -e "Имя диска: ${GREEN}$DISK${NC}"
    echo -e "Размер SWAP: $SWAP"
    echo -e "Размер ROOT: $ROOT"
    echo -e "Размер HOME: остаток места"
    yes_no_menu
    # Чистим диск
    sgdisk --zap-all /dev/$DISK
    # Разметка
    parted /dev/$DISK mklabel gpt
    parted /dev/$DISK mkpart ESP fat32 1MiB 513MiB
    parted /dev/$DISK set 1 esp on
    parted /dev/$DISK mkpart primary linux-swap 513MiB $((513+${SWAP%G}*1024))MiB
    parted /dev/$DISK mkpart primary ext4 $((513+${SWAP%G}*1024))MiB $((513+${SWAP%G}*1024+${ROOT%G}*1024))MiB
    parted /dev/$DISK mkpart primary ext4 $((513+${SWAP%G}*1024+${ROOT%G}*1024))MiB 100%
    # Форматирование
    mkfs.fat -F32 /dev/${DISK}p1
    mkswap /dev/${DISK}p2
    mkfs.ext4 -F /dev/${DISK}p3
    mkfs.ext4 -F /dev/${DISK}p4
    # Монтирование
    mount /dev/${DISK}p3 /mnt
    mkdir /mnt/{boot,home}
    mount /dev/${DISK}p1 /mnt/boot
    mount /dev/${DISK}p4 /mnt/home
    swapon /dev/${DISK}p2
}
# Создание разделов диска
disk_create() {
    disk_menu
    clear
    show_cursor
    echo -e "диск выбран: $SELECTED_DISK"
    read -e -p "Введите размер SWAP раздела (пример 8G): " -i "8G" SWAP
    echo -e "размаер SWAP: $SWAP"
    read -e -p "Введите размер ROOT раздела (пример 30G): " -i "30G" ROOT
    echo -e "размаер ROOT: $ROOT"
    hide_cursor
    sleep 1
    clear
            # Проверяем, содержит ли имя диска "nvme" или "mmcblk"
        if [[ "$SELECTED_DISK" == *nvme* || "$SELECTED_DISK" == *mmcblk* ]]; then
            nvme_disk_skript ;
        else
            sda_disk_skript ;
        fi
    sleep 1
    clear
    echo -e "   Разметка дисков завершена"
    press_screen
}
# Старт установки команды pacstrap
pacstrap_start() {
        load_screen
    if [ "$PING_STATUS" = "${GREEN}Есть соединение!${NC}" ]; then
        echo -e "   $PING_STATUS"
        sleep 1
    else
        echo -e "${RED}   Ошибка: Нет соединения с интернетом!${NC}"
        press_screen
        main_menu
    fi
    if [ "$DISK" = "" ]; then
        echo -e "${RED}   Ошибка: не выбран диск и не созданы разделы!!${NC}"
        press_screen
        main_menu
    else
        echo -e "диск выбран: $DISK"
        echo -e "размаер swap: $SWAP"
        echo -e "размаер swap: $ROOT"
        sleep 3
        yes_no_menu "   >    Начать установку?  <"
    fi
        clear
        echo -e "${GREEN}  Начинаю установку!${NC}"
            # Автоопределение процессора для выбора правильной строки initrd
            if grep -q "AuthenticAMD" /proc/cpuinfo; then
                UCODE_IMG="amd-ucode"
            elif grep -q "GenuineIntel" /proc/cpuinfo; then
                UCODE_IMG="intel-ucode"
            else
                # На случай виртуальных машин, чтобы не вызывать ошибку загрузчика
                UCODE_IMG=""
            fi
        sleep 3
    pacstrap /mnt base linux linux-firmware nano vim konsole $UCODE_IMG sbctl sudo firefox \
        plasma-meta dolphin kate bluez bluez-utils networkmanager sddm \
        ttf-dejavu noto-fonts noto-fonts-cjk tailscale openssh noto-fonts-emoji \
        git base-devel power-profiles-daemon bash-language-server
        echo -e "${GREEN}  Установка завершена успешно!${NC}"
    # fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    # Проверка, что файл существует и не пустой
    if [[ -s /mnt/etc/fstab ]]; then
        echo -e "${GREEN}  fstab успешно создан:${NC}"
        tail -n 10 /mnt/etc/fstab   # покажем последние строки для контроля
    else
        echo -e "${RED}   Ошибка: fstab не создан или пустой!${NC}"
        press_screen
        main_menu
    fi

    echo -e "${GREEN}  Базовая установка завершена. Теперь arch-chroot /mnt для пост-настроек.${NC}"
    press_screen
}
# Пост_настройка
post_install() {
clear_screen
# Создаём postinstall.sh внутри новой системы
        if [[ "$SELECTED_DISK" == *nvme* || "$SELECTED_DISK" == *mmcblk* ]]; then
            ROOT_UUID=$(blkid -s UUID -o value /dev/${DISK}p3) ;
        else
            ROOT_UUID=$(blkid -s UUID -o value /dev/${DISK}3) ;
        fi

cat << EOF > /mnt/root/postinstall.sh
#!/bin/bash

# Локаль
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf


# Время
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
hwclock -w

# systemd-boot
bootctl install || { echo "Ошибка: bootctl install не удалось"; exit 1; }

# убедимся, что каталог существует
mkdir -p /boot/loader/entries || { echo "Ошибка: не удалось создать каталог entries"; exit 1; }

cat > /boot/loader/entries/arch.conf <<EOL
title   Arch Linux
linux   /vmlinuz-linux
initrd  /$UCODE_IMG.img
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw
EOL

if [[ $? -ne 0 ]]; then
    echo "Ошибка: не удалось создать arch.conf"
    exit 1
fi

echo "timeout 0" > /boot/loader/loader.conf || { echo "Ошибка: не удалось записать loader.conf"; exit 1; }

echo "systemd-boot успешно установлен и конфиги созданы."

# Пользователи
echo "root:root" | chpasswd
useradd -m -G wheel -s /bin/bash admin
echo "admin:admin" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
usermod -aG video,audio,storage,optical,lp,scanner,network,users admin
# echo "Пользователи созданы!"

# Сервисы
systemctl enable power-profiles-daemon
systemctl enable fstrim.timer
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth
echo "Службы systemctl включены!"

# работа с ключами и подписями
sbctl create-keys
sbctl sign /boot/EFI/BOOT/BOOTX64.EFI || true
sbctl sign /boot/EFI/systemd/systemd-bootx64.efi || true
sbctl sign /boot/vmlinuz-linux || true
sbctl sign-all || true
sbctl bundle || true
sbctl enroll-keys || echo "Пропустил запись ключей в BIOS (сделайте вручную)"
echo "Установка ключей завершена!"

# установка yay
useradd -m builduser    || true
chmod 1777 /tmp || true
echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers    || true

# 3. Собираем yay от имени этого пользователя
sudo -u builduser bash -c "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm" || true

# 4. Убираем за собой
rm -rf /tmp/yay || true
userdel -r builduser || true
sed -i '/builduser/d' /etc/sudoers || true
echo "Установка yay завершена!"

# Конец скрипта постустановки
EOF

    chmod +x /mnt/root/postinstall.sh
    # Запускаем postinstall внутри chroot
    arch-chroot /mnt /root/postinstall.sh
    rm /mnt/root/postinstall.sh
    echo "${GREEN}  Установка завершена. Можно перезагружаться!${NC}"
    press_screen
}
# Перезагрузка
reboot_start() {
    clear_screen
    yes_no_menu "Перезагрузка?"
    # Попробуем размонтировать /mnt
    if umount -R /mnt; then
        echo -e "${GREEN}Разделы успешно размонтированы.${NC}"
        sleep 0.5
    else
        echo -e "${RED}Ошибка: не удалось размонтировать /mnt${NC}"
        sleep 0.5
    fi

    # Отключаем swap
    if swapoff -a; then
        echo -e "${GREEN}Swap отключён.${NC}"
        sleep 0.5
    else
        echo -e "${RED}Ошибка: не удалось отключить swap${NC}"
        sleep 0.5
    fi

    # Перезагрузка
    reboot || echo -e "${RED}ребут не удался!${NC}"
}
# Выключение
poweroff_start() {
    clear_screen
    yes_no_menu "Выключить?"
    # Попробуем размонтировать /mnt
    if umount -R /mnt; then
        echo -e "${GREEN}Разделы успешно размонтированы.${NC}"
        sleep 0.5
    else
        echo -e "${RED}Ошибка: не удалось размонтировать /mnt${NC}"
        sleep 0.5
    fi

    # Отключаем swap
    if swapoff -a; then
        echo -e "${GREEN}Swap отключён.${NC}"
        sleep 0.5
    else
        echo -e "${RED}Ошибка: не удалось отключить swap${NC}"
        sleep 0.5
    fi
    # Выключение
    shutdown -h now || echo -e "${RED}выключение не удалось!${NC}"
}
# запуск скрипта
    hide_cursor
    show_header
    clear_screen
    load_screen
    main_menu
