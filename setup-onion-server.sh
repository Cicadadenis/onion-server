#!/usr/bin/env bash                                     RED='\033[1;31m'
GREEN='\033[1;32m'                                      YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'
                                                        # Detect system
if [ -n "$PREFIX" ]; then
    OS="termux"                                             PKG_INSTALL="pkg install -y"                            PKG_UPDATE='pkg update -y && pkg upgrade -y -o Dpkg::Options::="--force-confold" && pkg install git -y'         TORRC="$PREFIX/etc/tor/torrc"
else
    OS="linux"
    PKG_INSTALL="sudo apt install -y"
    PKG_UPDATE='sudo apt update && sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && sudo apt install git -y'
    TORRC="/etc/tor/torrc"
fi


BASE_DIR=$HOME/tor-host
SITES_DIR=$BASE_DIR/sites
HS_DIR=$BASE_DIR/hidden_services
BACKUP_DIR=$BASE_DIR/backups

mkdir -p $SITES_DIR
mkdir -p $HS_DIR
mkdir -p $BACKUP_DIR

banner(){

clear

echo -e "$CYAN"
echo "╔══════════════════════════════╗"
echo "║        TOR HOST PANEL        ║"
echo "║            v5                ║"
echo "╚══════════════════════════════╝"
echo -e "$NC"

}

install_server(){

banner

echo -e "$YELLOW Установка пакетов...$NC"

eval $PKG_UPDATE
eval $PKG_INSTALL tor php curl git tar

echo -e "$YELLOW Установка Filebrowser...$NC"

curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

echo -e "$GREEN Установка завершена$NC"

sleep 3

}

create_site(){

banner

NAME="site"

SITE=$SITES_DIR/$NAME
HS=$HS_DIR/$NAME

mkdir -p $SITE
mkdir -p $HS

cat > $SITE/index.php <<EOF
<h1>🧅 $NAME</h1>
<p>Onion сайт работает</p>
<p><?php echo date("Y-m-d H:i:s"); ?></p>
EOF

# очищаем старый hidden service
sed -i '/HiddenServiceDir/d' $TORRC
sed -i '/HiddenServicePort/d' $TORRC

echo "HiddenServiceDir $HS" >> $TORRC
echo "HiddenServicePort 80 127.0.0.1:8080" >> $TORRC
echo "HiddenServicePort 8081 127.0.0.1:8081" >> $TORRC

echo -e "$GREEN Сайт создан$NC"

}

start_server(){

banner

SITE=$SITES_DIR/site

echo -e "$YELLOW Запуск PHP сервера...$NC"

php -S 127.0.0.1:8080 -t $SITE &

echo -e "$YELLOW Запуск Tor...$NC"

pkill tor 2>/dev/null
tor &

DB="$BASE_DIR/filebrowser.db"

if [ ! -f "$DB" ]; then

echo -e "$YELLOW Настройка Filebrowser...$NC"

filebrowser config init -d $DB
filebrowser users add admin cicada3301password --perm.admin -d $DB

fi

echo -e "$YELLOW Запуск файлового менеджера...$NC"

filebrowser -r $SITES_DIR -p 8081 -d $DB &

sleep 10

show_sites

}

show_sites(){

banner

echo -e "$GREEN Onion сайты:$NC"

for d in $HS_DIR/*; do

if [ -f "$d/hostname" ]; then

NAME=$(basename $d)
ONION=$(cat $d/hostname)

echo "$NAME → http://$ONION"

fi

done

echo ""

read -p "Enter..."

}

show_site_dir(){

banner

read -p "Имя сайта: " NAME

SITE=$SITES_DIR/$NAME

if [ -d "$SITE" ]; then

echo -e "$GREEN Директория:$NC"

ls -lah $SITE

else

echo -e "$RED Сайт не найден$NC"

fi

read -p "Enter..."

}

backup_sites(){

banner

DATE=$(date +%Y%m%d_%H%M)

tar -czf $BACKUP_DIR/sites_$DATE.tar.gz $SITES_DIR

echo -e "$GREEN Backup создан:$NC"
echo "$BACKUP_DIR/sites_$DATE.tar.gz"

read -p "Enter..."

}

while true
do

banner

echo "1) Установить сервер"
echo "2) Создать onion сайт"
echo "3) Запустить сервер"
echo "4) Показать onion сайты"
echo "5) Показать директорию сайта"
echo "6) Backup сайтов"
echo "7) Выход"

echo ""

read -p "Выберите: " choice

case $choice in

1) install_server ;;
2) create_site ;;
3) start_server ;;
4) show_sites ;;
5) show_site_dir ;;
6) backup_sites ;;
7) exit ;;

esac

done
