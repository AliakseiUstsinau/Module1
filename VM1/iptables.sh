#!/bin/bash
export IPT="iptables"

# WAN int
export WAN=enp0s3
export WAN_IP=10.0.2.11

# Local int
export LAN=enp0s8
export LAN_IP_RANGE=192.168.56.0/24

# clear all
$IPT -F
$IPT -F -t nat
$IPT -F -t mangle
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X

#block all traffic
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

#enable local traffic LAN & localhost
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A INPUT -i $LAN -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
$IPT -A OUTPUT -o $LAN -j ACCEPT

#enable ping
$IPT -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

#enable inet for server
$IPT -A OUTPUT -o $WAN -j ACCEPT

#enable established connections
$IPT -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT

#blocking packets with no status
$IPT -A INPUT -m state --state INVALID -j DROP
$IPT -A FORWARD -m state --state INVALID -j DROP

#blocking empty packets
$IPT -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

#blocking syn-flood attacks
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A OUTPUT -p tcp ! --syn -m state --state NEW -j DROP

#enable inet from LAN
$IPT -A FORWARD -i $LAN -o $WAN -j ACCEPT

#block ip from LAN to WAN
$IPT -A INPUT -s 192.168.56.13 -j DROP

#disable LAN from inet
$IPT -A FORWARD -i $WAN -o $LAN -j REJECT

#enable NAT
$IPT -t nat -A POSTROUTING -o $WAN -s $LAN_IP_RANGE -j MASQUERADE

#enable ssh
$IPT -A INPUT -i $WAN -p tcp --dport 22 -j ACCEPT

#save rules after reboot
/sbin/iptables-save > /etc/sysconfig/iptables