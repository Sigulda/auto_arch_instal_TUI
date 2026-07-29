#!/bin/bash
set -e

# Приветствие и вопросы

echo "Добро пожаловать в автоустановщик арч с кде плазма"

read -p "Продолжить установку? (y/n): " answer
answer=${answer:-Y}
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Продолжаем установку..."
else
    echo "Установка прервана."
    exit 1
fi

# 1-1 сеть!!!
# Проверка сети через ping
if ping -c 3 archlinux.org >/dev/null 2>&1; then
    echo "Сеть доступна, продолжаем установку..."
else
    echo "Сеть недоступна. Настройте Wi-Fi вручную:"
    echo "station list"
    echo "station <ваш адаптер> scan"
    echo "station <ваш адаптер> get-networks"
    echo "station <ваш адаптер> connect <ваш Wi-Fi>"
    iwctl

    # Повторная проверка после выхода из iwctl
    if ping -c 3 archlinux.org >/dev/null 2>&1; then
        echo "Сеть успешно настроена, продолжаем установку..."
    else
        echo "Сеть всё ещё недоступна. Установка прервана."
        exit 1
    fi
fi

# 1. Выбор диска
lsblk -d -o NAME,SIZE,MODEL
DISK=$(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print $1; exit}')

# 2. Вопросы по размерам
SWAP=8G
ROOT=30G
HOME=70G

# 3. Чистим диск
sgdisk --zap-all /dev/$DISK

# 4. Разметка
parted /dev/$DISK mklabel gpt
parted /dev/$DISK mkpart ESP fat32 1MiB 513MiB
parted /dev/$DISK set 1 esp on
parted /dev/$DISK mkpart primary linux-swap 513MiB $((513+${SWAP%G}*1024))MiB
parted /dev/$DISK mkpart primary ext4 $((513+${SWAP%G}*1024))MiB $((513+${SWAP%G}*1024+${ROOT%G}*1024))MiB
parted /dev/$DISK mkpart primary ext4 $((513+${SWAP%G}*1024+${ROOT%G}*1024))MiB 100%

# 5. Форматирование
mkfs.fat -F32 /dev/${DISK}1
mkswap /dev/${DISK}2
mkfs.ext4 -F /dev/${DISK}3
mkfs.ext4 -F /dev/${DISK}4

# 6. Монтирование
mount /dev/${DISK}3 /mnt
mkdir /mnt/{boot,home}
mount /dev/${DISK}1 /mnt/boot
mount /dev/${DISK}4 /mnt/home
swapon /dev/${DISK}2


# 8. Установка
pacstrap /mnt base linux linux-firmware nano vim konsole intel-ucode sbctl sudo firefox \
    plasma-meta dolphin kate bluez bluez-utils networkmanager sddm \
    ttf-dejavu noto-fonts noto-fonts-cjk tailscale openssh
#    kwin-x11 plasma-x11-session


# 9. fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Проверка, что файл существует и не пустой
if [[ -s /mnt/etc/fstab ]]; then
    echo "fstab успешно создан:"
    tail -n 10 /mnt/etc/fstab   # покажем последние строки для контроля
else
    echo "Ошибка: fstab не создан или пустой!"
    exit 1
fi

echo ">>> Базовая установка завершена. Теперь arch-chroot /mnt для пост-настроек."

read -p "Продолжить установку? (y/n): " answer
answer=${answer:-Y}
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Продолжаем установку..."
else
    echo "Установка прервана."
    exit 1
fi


# === 10. Создаём postinstall.sh внутри новой системы ===

ROOT_UUID=$(blkid -s UUID -o value /dev/${DISK}3)

cat << EOF > /mnt/root/postinstall.sh
#!/bin/bash
set -e

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
initrd  /intel-ucode.img
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


# Сервисы
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth
systemctl enable tailscaled
systemctl enable sshd
systemctl start tailscaled
systemctl start sshd

# работа с ключами и подписями
sbctl create-keys
sbctl sign /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign /boot/EFI/systemd/systemd-bootx64.efi
sbctl sign /boot/vmlinuz-linux
sbctl sign-all
sbctl bundle
sbctl enroll-keys

# Создание подключения в меш сеть и открытие порта для sshd
TAILSCALE_AUTHKEY="tskey-auth-"
SSH_PUBLIC_KEY="ssh-"
tailscale up --authkey $TAILSCALE_AUTHKEY

# добавление ssh key
mkdir -p ~/.ssh
echo "$SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh



exit
EOF

chmod +x /mnt/root/postinstall.sh


# === 11. Запускаем postinstall внутри chroot ===
arch-chroot /mnt /root/postinstall.sh
rm /mnt/root/postinstall.sh

echo ">>> Установка завершена. Можно перезагружаться!"

# Небольшая пауза, чтобы успеть прочитать сообщение
sleep 5

# Попробуем размонтировать /mnt
if umount -R /mnt; then
    echo "Разделы успешно размонтированы."
else
    echo "Ошибка: не удалось размонтировать /mnt"
    exit 1
fi

# Отключаем swap
if swapoff -a; then
    echo "Swap отключён."
else
    echo "Ошибка: не удалось отключить swap"
    exit 1
fi

# Перезагрузка
reboot -h now
