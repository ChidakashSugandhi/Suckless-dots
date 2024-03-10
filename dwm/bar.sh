#! /bin/bash

print_power() {
    status="$(cat /sys/class/power_supply/AC0/online)"
    battery="$(cat /sys/class/power_supply/BAT0/capacity)"
    timer="$(acpi -b | grep "Battery" | awk '{print $5}' | cut -c 1-5)"
    if [ "${status}" == 1 ]; then
        echo -ne "${battery}%"
    else
        echo -ne "^c#EBCB8B^ ^d^${battery}%"
    fi
}

print_backlight() {
    bl="$(xbacklight | sed 's/\..*//')"
    echo -ne "${bl}%"
}

print_wifi() {
    wifissid="$(nmcli -t -f NAME connection show --active)"
    wifiperc="$(grep "^\s*w" /proc/net/wireless | awk '{ print int($3 * 100 / 70) "%" }')"
    echo -ne "${wifiperc} ${wifissid}"
}

print_volume() {
    mix=`amixer get Master | tail -1`
    vol="$(amixer get Master | tail -n1 | sed -r 's/.*\[(.*)%\].*/\1/')"
    if [[ $mix == *\[off\]* ]]; then
        echo -ne "Muted"
    elif [[ $mix == *\[on\]* ]]; then
        echo -ne "${vol}%"
    fi
}

print_date() {
    date="$(LC_ALL=C date "+%a %d %b")"
    echo -ne "${date}"
}

print_time() {
    time="$(date "+%H:%M")"
    echo -ne "${time}"
}

print_spotify() {
    if ! pgrep -x spotify >/dev/null; then
        echo ""; exit
    fi

    cmd="org.freedesktop.DBus.Properties.Get"
    domain="org.mpris.MediaPlayer2"
    path="/org/mpris/MediaPlayer2"

    meta=$(dbus-send --print-reply --dest=${domain}.spotify \
        /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:${domain}.Player string:Metadata)

    artist=$(echo "$meta" | sed -nr '/xesam:artist"/,+2s/^ +string "(.*)"$/\1/p' | tail -1  | sed "s/\&/+/g")
    album=$(echo "$meta" | sed -nr '/xesam:album"/,+2s/^ +variant +string "(.*)"$/\1/p' | tail -1)
    title=$(echo "$meta" | sed -nr '/xesam:title"/,+2s/^ +variant +string "(.*)"$/\1/p' | tail -1 | sed "s/\&/+/g")

    echo -ne "^c#A3BE8C^ ^d^${*:-%artist% - %title%}" | sed "s/%artist%/$artist/g;s/%title%/$title/g;s/%album%/$album/g"i | sed 's/&/\\&/g'
}

print_wttr() {
	loc="Jülich"
	wttr="$(curl -s v2.wttr.in/${loc} | grep -e "Weather" | sed 's/C,.*/C/g; s/+//g; s/.*\[0m.//g; s/.//2')"
	echo -ne "${wttr}"
}

while true; do
	# xsetroot -name "$(print_wifi)  |  $(print_power) | $(print_backlight)  $(print_volume)  $(print_date)  $(print_time) "
	xsetroot -name "$(print_wifi)  |  $(print_power)  |  $(print_volume)  |  $(print_time)  |"

    sleep 1
done
