#!/bin/bash

# Название интерфейса
export interface_name="enp6s0"
engine_fqdn="krvengine.testing.test"
host_fqdn="krvhost.testing.test"



function get_parsed_ip {
# Получаем вывод команды ip a
local output=$(ip a)

# Фильтруем строки, содержащие имя интерфейса
local interface_lines=$(echo "$output" | grep $interface_name)

local ip_address=$(echo "$interface_lines" | awk '/inet / {print $2}')
eval ip_address=$(echo "$ip_address" | cut -d'/' -f1)

echo $ip_address
}





ip_address_1=$(get_parsed_ip)
if [ -z "$ip_address_1" ]; then
    echo "IP-адрес 1 не определен"
    exit 2
fi




export ip_address_2=""

while true; do
  # Меняем mac-адрес интерфейса
  new_mac_address=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
  echo "$new_mac_address <- new mac-address"

  # Запрашиваем новые ip у DHCP-сервера
  dhclient -v -r $interface_name
  ip link set dev $interface_name down
  ip link set dev $interface_name address $new_mac_address
  ip link set dev $interface_name up
  dhclient -v $interface_name



  # Получите новый IP-адрес сетевого интерфейса
  ip_address_2=$(get_parsed_ip)


  # Проверьте, являются ли IP-адреса разными
  if [ "$ip_address_2" != "$ip_address_1" ]; then
    # Если IP-адреса разные, выведите сообщение и выйдите из цикла
    echo "IP-адреса сетевого интерфейса изменились с $ip_address_1 на $ip_address_2"
    break
  fi

  # Ждите 1 секунду перед следующим прохождением цикла
  sleep 1
done


if [ -z "$ip_address_2" ]; then
    echo "IP-адрес 2 не определен"
    exit 2
fi




etc_hosts_info="
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$ip_address_1 $engine_fqdn
$ip_address_2 $host_fqdn
"

engine_info="
{
  \"code\": 0,
  \"output\": {
    \"engine_ip\": \"$ip_address_1\",
    \"engine_fqdn\": \"$engine_fqdn\"
  }
}
"

host_info="
device $interface_name
host_ip $ip_address_2
host_fqdn $host_fqdn
"

echo "$etc_hosts_info" > /etc/hosts
echo "$engine_info" > ./engine.info
echo "$host_info" > ./host.info















cleanup() {  
    engine_info='
  {
    "code": "error",
  }
'
    echo "$engine_info" > ./engine.info
}

trap cleanup INT

./ip_probe.sh 2> combined.log