#!/bin/sh

# Configure iptables for accept cloudflare 80 and 443 only


iptables -F
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -i lo -j ACCEPT

DIR="$(dirname $(readlink -f $0))"
cd $DIR
wget https://www.cloudflare.com/ips-v4 -O ips-v4.tmp
wget https://www.cloudflare.com/ips-v6 -O ips-v6.tmp
mv ips-v4.tmp ips-v4
mv ips-v6.tmp ips-v6

for cfip in `cat ips-v4`; do iptables -A INPUT -p tcp -s  $cfip -m tcp --dport 80 -j ACCEPT; done
for cfip in `cat ips-v4`; do iptables -A INPUT -p tcp -s  $cfip -m tcp --dport 443 -j ACCEPT; done

iptables -A INPUT -p tcp -s $1 -m tcp --dport 22 -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 1025:65535 -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -P OUTPUT DROP
iptables -P INPUT DROP

iptables -L -n


iptables-save | sudo tee /etc/sysconfig/iptables
service iptables restart
