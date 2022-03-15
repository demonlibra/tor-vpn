#!/bin/bash

#dns="77.88.8.8"
#dns="8.8.8.8"
#dns="208.67.222.123"
#dns="89.233.43.71"
#dns="1.1.1.3"
dns="127.0.2.1"															#IP адрес для dnscrypt

connection_name=`nmcli -g name,type connection  show  --active \
		| awk -F: '/ethernet|wireless/ { print $1 }'`					# Имя подключения к точке доступа

mode=`gsettings get org.gnome.system.proxy mode`
if [[ `gsettings get org.gnome.system.proxy mode` == "'manual'" ]]
	then proxy_status="Включен"
	else proxy_status="Отключен"
fi
	
dialog --title "Proxy" --ok-label "Включить" --cancel-label "Отключить" \
		--extra-button --extra-label "Рестарт" --default-button extra \
		--pause "$proxy_status" 9 40 5
form="$?"
clear

if [ "$form" == "0" ] || [ "$form" == "3" ]
	then
		echo "Введите пароль"
		sudo echo

		nmcli con mod "$connection_name" ipv4.dns "$dns"				# Задание IP адреса DNS сервера
		nmcli con mod "$connection_name" ipv4.ignore-auto-dns yes		# Отключение автоматического получения IP адреса DNS от маршрутизатора
		nmcli con mod "$connection_name" ipv6.method ignore				# Отключение IPV6

		nmcli radio all off												# Выключение Wi-Fi
		sleep 1															# Пауза 1 секунду
		nmcli radio wifi on												# Включение Wi-Fi
		sleep 2															# Пауза 2 секунды

		sudo service tor restart										# Сброс сервиса tor
		sudo service privoxy restart									# Сброс сервиса privoxy
		sudo systemctl restart dnscrypt-proxy							# Сброс сервиса dnscrypt

		gsettings set org.gnome.system.proxy mode 'manual'				# Прокси вручную
		notify-send -i "gtk-ok" "Proxy" "Заданы настройки вручную"		# Вывод уведомления
	
elif [ $? == "1" ]														# Выключение proxy
	then
		clear
		nmcli con mod "$connection_name" ipv4.ignore-auto-dns no		# Включение получения адреса DNS от маршрутизатора
		gsettings set org.gnome.system.proxy mode 'none'				# Если прокси был включен, выключить прокси

		nmcli radio all off												# Выключение Wi-Fi
		sleep 1															# Пауза 1 секунду
		nmcli radio wifi on												# Включение Wi-Fi
		sleep 2															# Пауза 2 секунды

		notify-send -i "gtk-ok" "Proxy" "Отключен"						# Вывод уведомления
fi
