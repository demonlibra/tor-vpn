#!/bin/bash

#dns="77.88.8.8"				# IP адрес DNS Yandex 
#dns="8.8.8.8"					# IP адрес DNS Google
#dns="208.67.222.123"			# IP адрес Cisco Umbrella (OpenDNS)
#dns="89.233.43.71"				# IP адрес UncensoredDNS
#dns="1.1.1.3"					# IP адрес Cloudflare DNS

dns="127.0.2.1"					# IP адрес dnscrypt

connection_name=`nmcli -g name,type connection  show  --active \
		| awk -F: '/ethernet|wireless/ { print $1 }'`					# Имя подключения к точке доступа

tempfile=`mktemp 2>/dev/null`
dialog --title "Internet" --ok-label "Выбрать" --cancel-label "Выход" \
		--default-item 2 --menu " " 15 47 7 \
		"1" "Tor и прокси" \
		"2" "ProtonVPN автоматическое подключение" \
		"3" "ProtonVPN ручной выбор" \
		"4" "Обычное подключение" \
		"5" "Проверка подключения" \
		"6" "Выключить сеть" \
		"7" "Сброс сетевых сервисов" \
		2> $tempfile

form="$?"
choice=`cat $tempfile`

clear

# ======================================================================
# ------------------------------- Tor ----------------------------------
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
if [ "$choice" == "1" ]
	then
		if [[ `nmcli | grep "proton"` ]]
			then
				echo "Отключение от VPN"
				protonvpn-cli disconnect
				protonvpn-cli ks --off
			fi

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
			fi

		echo
		nmcli networking off											# Выключение сети
		echo "Выключение сети"
		sleep 3
		nmcli networking on												# Включение Wi-Fi
		echo "Включение сети"
		echo

		echo
		echo "Введите пароль"
		echo
		sudo echo

		while [[ ! `nmcli device status | grep "wifi" | grep "подключено"` ]] \
			&& [[ ! `nmcli device status | grep "usb" | grep "подключено"` ]] # Проверка подключения к сети wifi
			do
				echo "Ожидание подключения Wi-Fi или USB-модема"
				sleep 3
			done

		sudo service tor restart										# Сброс сервиса tor
		echo "Сброс сервиса tor"
		sudo service privoxy restart									# Сброс сервиса privoxy
		echo "Сброс сервиса privoxy"
		sudo systemctl restart dnscrypt-proxy							# Сброс сервиса dnscrypt
		echo "Сброс сервиса dnscrypt"
		echo
		gsettings set org.gnome.system.proxy mode 'manual'				# Прокси вручную
		echo "Задание настроек прокси вручную"
		sleep 3
# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



# ======================================================================
# ------------------------------- ProtonVPN ----------------------------
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
elif [ "$choice" == "2" ] || [ "$choice" == "3" ]						
	then
		if [[ `gsettings get org.gnome.system.proxy mode` == "'manual'" ]]
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
			fi

		if [[ `nmcli | grep "proton"` ]]
			then
				echo "Отключение от VPN"
				echo
				protonvpn-cli disconnect
				protonvpn-cli ks --off
				sleep 1
			fi

		echo
		nmcli networking  off											# Выключение сети
		echo "Выключение сети"
		sleep 3	
		nmcli networking on												# Включение сети
		echo "Включение сети"
		echo

		while [[ ! `nmcli device status | grep "wifi" | grep "подключено"` ]] \
			&& [[ ! `nmcli device status | grep "usb" | grep "подключено"` ]] # Проверка подключения к сети wifi
			do
				echo "Ожидание подключения Wi-Fi или USB-модема"
				sleep 3
			done

		echo
		if [ "$choice" == "2" ]											# ProtonVPN Auto
			then
				while [ "$connect_status" != "0" ]
					do
						protonvpn-cli connect --fastest
						connect_status=$?
						sleep 3
						echo
					done
			fi

		if [ "$choice" == "3" ]											# ProtonVPN Manual
			then
				while [ "$connect_status" != "0" ]
					do
						protonvpn-cli connect
						connect_status=$?
						sleep 3
						echo
					done
			fi
# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



# ======================================================================
# --------------- # Выключение Tor, Proxy и ProtonVPN ------------------
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

elif [ "$choice" == "4" ]
	then
		if [[ `nmcli | grep "proton"` ]]
			then 
				protonvpn-cli disconnect
				#protonvpn-cli ks --off
				echo
			fi

		protonvpn-cli ks --off
		
		if [[ `gsettings get org.gnome.system.proxy mode` == "'manual'" ]]
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
			fi

		echo
		nmcli networking off											# Выключение сети
		echo "Выключение сети"
		sleep 3	
		nmcli networking on												# Включение сети
		echo "Включение сети"
		echo

		while [[ ! `nmcli device status | grep "wifi" | grep "подключено"` ]] \
			&& [[ ! `nmcli device status | grep "usb" | grep "подключено"` ]] # Проверка подключения к сети wifi
			do
				echo "Ожидание подключения Wi-Fi или USB-модема"
				sleep 3
			done
# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



# ======================================================================
# ----------------------- Проверка подключения -------------------------
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
elif [ "$choice" == "5" ]
	then
		for ((;;))
			do
				if [[ `fping --alive 1.1.1.1 8.8.8.8` ]]
					then
						#killall -q mpv
						pacmd set-sink-volume "alsa_output.pci-0000_00_1f.3.analog-stereo" 60000
						echo -e `date +%T`" Internet OK\n"
						mpv --no-terminal "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
						pacmd set-sink-volume "alsa_output.pci-0000_00_1f.3.analog-stereo" 20000
						sleep 10
					else
						echo -e `date +%T`" No internet connection\n"
						sleep 60
					fi
			done
# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


# ======================================================================
# --------------------------- Выключить сеть ---------------------------
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
elif [ "$choice" == "6" ]
	then
		echo
		nmcli networking off											# Выключение сети
		echo "Выключение сети"

# ======================================================================
# ---------------------- Сброс сетевых сервисов ------------------------
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
elif [ "$choice" == "7" ]
	then
		protonvpn-cli disconnect
		protonvpn-cli ks --off

		echo
		sudo systemctl restart networking
		sleep 3
		echo
		sudo systemctl restart NetworkManager
		#echo ""

fi
