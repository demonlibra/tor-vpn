#!/bin/bash

mode=`gsettings get org.gnome.system.proxy mode`
#dns="77.88.8.8"
#dns="8.8.8.8"
#dns="208.67.222.123"
#dns="89.233.43.71"
#dns="1.1.1.3"
dns="127.0.2.1"

connection_name=`nmcli -g name,type connection  show  --active \
		| awk -F: '/ethernet|wireless/ { print $1 }'`					# Имя подключения к точке доступа

if [[ `gsettings get org.gnome.system.proxy mode` == "'manual'" ]]
	then proxy_status="Включен"
	else proxy_status="Отключен"
fi
	
dialog --title "Proxy" --ok-label "Включить" --cancel-label "Отключить" \
		--extra-button --extra-label "Рестарт" --default-button extra \
		--pause "$proxy_status" 9 40 5
form="$?"

clear
echo "Введите пароль"
sudo echo

if [ "$form" == "0" ] || [ "$form" == "3" ]
	then
		nmcli con mod "$connection_name" ipv4.dns "$dns"				# Задание DNS сервера
		nmcli con mod "$connection_name" ipv4.ignore-auto-dns yes		# Отключение получения адреса DNS от маршрутизатора
		nmcli con mod "$connection_name" ipv6.method ignore				# Отключение IPV6

		nmcli radio all off												# Выключение Wi-Fi
		sleep 1
		nmcli radio wifi on												# Включение Wi-Fi
		sleep 2

		sudo service tor restart
		sudo service privoxy restart
		sudo systemctl restart dnscrypt-proxy

		gsettings set org.gnome.system.proxy mode 'manual'				# Прокси вручную
		notify-send -i "gtk-ok" "Proxy" "Заданы настройки вручную"		# Вывод уведомления
	
elif [ $? == "1" ]														# Выключение proxy
	then
		clear
		nmcli con mod "$connection_name" ipv4.ignore-auto-dns no		# Включение получения адреса DNS от маршрутизатора
		gsettings set org.gnome.system.proxy mode 'none'				# Если прокси был включен, выключить прокси

		nmcli radio all off												# Выключение Wi-Fi
		sleep 1
		nmcli radio wifi on												# Включение Wi-Fi
		sleep 2

		notify-send -i "gtk-ok" "Proxy" "Отключен"						# Вывод уведомления
fi
