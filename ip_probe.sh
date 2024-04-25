#!/bin/bash
set_current_ip_to_static () {
CURRENT_IP=$(ip -o -4 addr show dev $(ip route | grep default | awk '{print $5}') | awk '{split($4,a,"/");print a[1]}') && CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}') && CURRENT_DNS=$(nmcli device show $(ip route | grep default | awk '{print $5}') | grep IP4.DNS | awk '{print $2}') && nmcli connection modify $(ip route | grep default | awk '{print $5}') ipv4.method manual ipv4.addresses "$CURRENT_IP/24" ipv4.gateway $CURRENT_GATEWAY ipv4.dns "$CURRENT_DNS"
}

set_hostname () {
CURRENT_IP=$(ip -o -4 addr show dev $(ip route | grep default | awk '{print $5}') | awk '{split($4,a,"/");print a[1]}')
LAST_PART=$(echo $CURRENT_IP | awk -F. '{print $4}')
hostnamectl set-hostname autorvhost$LAST_PART.test
}

gen_ip () {
        fping -qug 10.81.81.0/24 | shuf -n 1
}

IP=$(gen_ip)
LAST_PART=$(echo $IP | awk -F. '{print $4}')
FQDN=$"autorvengine$LAST_PART.test"

echo "$IP $FQDN $LAST_PART"

engine_info="{
    'engine_ip':'$IP',
    'engine_fqdn':'$FQDN'
}"
set_current_ip_to_static
set_hostname
echo $engine_info > engine.info
