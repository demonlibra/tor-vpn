#!/bin/bash

#dns="77.88.8.8"
#dns="8.8.8.8"
#dns="208.67.222.123"
#dns="89.233.43.71"
#dns="1.1.1.3"
dns="127.0.2.1"																# IP адрес для dnscrypt

connection_name=`nmcli -g name,type connection  show  --active \
		| awk -F: '/ethernet|wireless/ { print $1 }'`						# Имя подключения к точке доступа

mode=`gsettings get org.gnome.system.proxy mode`							# Текущее состояние proxy
if [[ `gsettings get org.gnome.system.proxy mode` == "'manual'" ]]
	then proxy_status="\nProxy Включен"
	else proxy_status="\nProxy Отключен"
fi

dialog --title "Tor & Proxy" --ok-label "Рестарт" --cancel-label "Выход" \
		--extra-button --extra-label "Отключить" --default-button ok \
		--pause "$proxy_status" 9 40 5
form="$?"
clear

if [ "$form" == "0" ]
	then
		if [ "$connection_name" ]
			then
				echo
				echo "Название подключения: $connection_name"
				
				nmcli con mod "$connection_name" ipv4.dns "$dns"				# Задание IP адреса DNS сервера
				echo
				echo "Задание IP адреса DNS: $dns"
				nmcli con mod "$connection_name" ipv4.ignore-auto-dns yes		# Отключение автоматического получения IP адреса DNS от маршрутизатора
				echo "Отключение автоматического получения IP адреса DNS от маршрутизатора"
				nmcli con mod "$connection_name" ipv6.method ignore				# Отключение IPV6
				echo "Отключение IPV6"
				echo
			fi

		if [[ `nmcli radio wifi` == "enabled" ]]
			then
				nmcli radio all off											# Выключение Wi-Fi
				echo "Выключение Wi-Fi"
			fi

		echo
		echo "Введите пароль"
		echo
		sudo echo

		nmcli radio wifi on													# Включение Wi-Fi
		echo "Включение Wi-Fi"
		echo

		while [[ ! `nmcli device status | grep "wifi" | grep "подключено"` ]]	# Проверка подключения к сети wifi
			do
				sleep 1
			done

		sudo service tor restart											# Сброс сервиса tor
		echo "Сброс сервиса tor"
		sudo service privoxy restart										# Сброс сервиса privoxy
		echo "Сброс сервиса privoxy"
		sudo systemctl restart dnscrypt-proxy								# Сброс сервиса dnscrypt
		echo "Сброс сервиса dnscrypt"
		echo
		gsettings set org.gnome.system.proxy mode 'manual'					# Прокси вручную
		echo "Задание настроек прокси вручную"
		sleep 3

		#notify-send -i "gtk-ok" "Proxy" "Заданы настройки вручную"			# Вывод уведомления

elif [ "$form" == "3" ]														# Выключение proxy
	then
		if [ "$connection_name" ]
			then
				echo
				echo "Название подключения: $connection_name"

				nmcli con mod "$connection_name" ipv4.ignore-auto-dns no	# Включение получения адреса DNS от маршрутизатора
				echo
				echo "Включение автоматического получения IP адреса DNS от маршрутизатора"
			fi

		gsettings set org.gnome.system.proxy mode 'none'					# Если прокси был включен, выключить прокси
		echo "Отключение использования прокси"
		echo

		if [[ `nmcli radio wifi` == "enabled" ]]
			then
				nmcli radio all off											# Выключение Wi-Fi
				echo "Выключение Wi-Fi"
				sleep 1														# Пауза 1 секунду
			fi

		nmcli radio wifi on													# Включение Wi-Fi
		echo "Включение Wi-Fi"
		sleep 3																# Пауза 3 секунды

		#notify-send -i "gtk-ok" "Proxy" "Отключен"							# Вывод уведомления
fi
