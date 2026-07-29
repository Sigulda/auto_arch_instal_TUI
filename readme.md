# авто установщик для арч c TUI меню


### инструкция по установки для сборки если у вас archlinux
Теперь скопируйте профиль на Ваш выбор, в каталог (~/archlive используется в примере ниже), в котором вы можете вносить корректировки. Выполните следующую команду, заменив profile либо на releng, либо на baseline.
```
cp -r /usr/share/archiso/configs/releng/ ~/archlive
```

Настройка live носителя
packages.x86_64 — это где вы перечисляете построчно пакеты, которые вы хотите установить, и
каталог airootfs — это каталог, действующий как наложение, и именно там вы делаете все настройки.


по пути ``` ~/archlive/airootfs/root/ ``` вставляем наш скрипт
***если вам не важно автозапуск делать, и вы используете английский в системе то можно вызвать скрипт в live образе в терминале***
#### Сначала монтируем USB flesh

```
mkdir /usb
mount /dev/sdb1 /usb
```
##### активация файла для исполнения chmod
```
chmod +x ./auto_main_menu_TUI.sh
```
запуск файла
```
./auto_main_menu_TUI.sh
```
#### настройка автозапуска скрипта при входе в live образ
Добавляем скрипт в автозапуск при входе
```
echo "~/auto_main_menu_TUI.sh" >> ~/archlive/airootfs/root/.zlogin
```
выдаем права на запуск скрипта
в файл ~/archlive/profiledef.sh
```
  ["/root/auto_main_menu_TUI.sh"]="0:0:755"
  ["/etc/vconsole.conf"]="0:0:644" # эту строку ставим для прав локали (смотри далее) если используем русский язык
```
либо команда:
```
sed -i '/file_permissions=(/a \  ["/root/auto_main_menu_TUI.sh"]="0:0:755"\n  ["/etc/vconsole.conf"]="0:0:644"' ~/archlive/profiledef.sh
```
далее настроить русский язык
```
echo "LANG=ru_RU.UTF-8" > ~/archlive/airootfs/etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> ~/archlive/airootfs/etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> ~/archlive/airootfs/etc/locale.gen
echo "KEYMAP=ru" >> ~/archlive/airootfs/etc/vconsole.conf
echo "FONT=cyr-sun16" >> ~/archlive/airootfs/etc/vconsole.conf
# Шрифты в live образ
echo "noto-fonts" >> ~/archlive/packages.x86_64
echo "ttf-liberation" >> ~/archlive/packages.x86_64
```

#### Сборка ISO

Создайте ISO, который затем можно записать на компакт-диск или USB, запустив:
***mkarchiso -v -w /путь/до/рабочей_директории -o /путь/до/выходной_директории /путь/до/профиля/***

    -w указывает рабочий каталог. Если параметр не указан, по умолчанию он будет работать в текущем каталоге.
    -o указывает каталог, в который будет помещен созданный ISO-образ. Если параметр не указан, по умолчанию он будет выводить в текущий каталог.
    Следует отметить, что файл профиля profiledef.sh не может быть указан при запуске mkarchiso, только путь к файлу
    
Финальная команда для сборки вашего уникального образа будет выглядеть так:
```
sudo mkarchiso -v -w ~/archlive/work -o ~/archlive/out ~/archlive/
```

Удалить
```
sudo rm ~/iso/arch*.iso
sudo rm ~/archlive/out/*.iso
sudo rm -rf ~/archlive/work
```
