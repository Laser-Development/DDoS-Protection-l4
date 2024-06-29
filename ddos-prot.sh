#!/bin/sh

#########################################################
#              Laser DDOS PROTECTION SCRIPT             #
#########################################################
#                       CONTACT                         #
#########################################################
#              DEVELOPER : Abhishek                     #
#########################################################

# For debugging use iptables -v.
IPTABLES="/sbin/iptables"

# Logging options.
LOG="LOG --log-level debug --log-tcp-sequence --log-tcp-options"
LOG="$LOG --log-ip-options"

# Defaults for rate limiting
RLIMIT="-m limit --limit 3/s --limit-burst 8"

# Unprivileged ports.
PHIGH="1024:65535"
PSSH="1000:1023"

# SYN Flood Protection
$IPTABLES -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 10 -j ACCEPT
$IPTABLES -A INPUT -p tcp --syn -m recent --name SYN_FLOOD --set -j REJECT --reject-with tcp-reset

# UDP Flood Protection
$IPTABLES -A INPUT -p udp -m limit --limit 10/s --limit-burst 20 -j ACCEPT
$IPTABLES -A INPUT -p udp -m recent --name UDP_FLOOD --set -j REJECT --reject-with icmp-port-unreachable

# ICMP Flood Protection
$IPTABLES -A INPUT -p icmp -m limit --limit 1/s --limit-burst 10 -j ACCEPT
$IPTABLES -A INPUT -p icmp -m recent --name ICMP_FLOOD --set -j REJECT --reject-with icmp-host-unreachable

# TCP Flood Protection
$IPTABLES -A INPUT -p tcp -m limit --limit 10/s --limit-burst 20 -j ACCEPT
$IPTABLES -A INPUT -p tcp -m recent --name TCP_FLOOD --set -j REJECT --reject-with tcp-reset

# Drop invalid packets
$IPTABLES -A INPUT -m state --state INVALID -j DROP

# Drop packets with bogus TCP flags
$IPTABLES -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Drop packets with bogus UDP flags
$IPTABLES -A INPUT -p udp --udp-flags ALL ALL -j DROP

# Drop packets with bogus ICMP flags
$IPTABLES -A INPUT -p icmp --icmp-type ALL -j DROP

# Save and restart iptables
service iptables save
service iptables restart

echo "Layer 4 DDOS Protection Script Installed Successfully!"
