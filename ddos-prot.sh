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
IP6TABLES="/sbin/ip6tables"
MODPROBE="/sbin/modprobe"
RMMOD="/sbin/rmmod"
ARP="/usr/sbin/arp"

# Logging options.
#------------------------------------------------------------------------------
LOG="LOG --log-level debug --log-tcp-sequence --log-tcp-options"
LOG="$LOG --log-ip-options"

# Defaults for rate limiting
#------------------------------------------------------------------------------
RLIMIT="-m limit --limit 3/s --limit-burst 8"

# Unprivileged ports.
#------------------------------------------------------------------------------
PHIGH="1024:65535"
PSSH="1000:1023"

# Load required kernel modules
#------------------------------------------------------------------------------
$MODPROBE ip_conntrack_ftp
$MODPROBE ip_conntrack_irc
$MODPROBE nf_conntrack
$MODPROBE nf_conntrack_ftp
$MODPROBE nf_conntrack_irc

# Layer 4 DDOS Protection
#------------------------------------------------------------------------------

# SYN Flood Protection
$IPTABLES -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 10 -j ACCEPT
$IPTABLES -A INPUT -p tcp --syn -m recent --name SYN_FLOOD --set -j REJECT --reject-with tcp-reset

# UDP Flood Protection
$IPTABLES -A INPUT -p udp -m limit --limit 10/s --limit-burst 20 -j ACCEPT
$IPTABLES -A INPUT -p udp -m recent --name UDP_FLOOD --set -j REJECT --reject-with icmp-port-unreachable

# ICMP Flood Protection
$IPTABLES -A INPUT -p icmp -m limit --limit 1/s --limit-burst 10 -j ACCEPT
$IPTABLES -A INPUT -p icmp -m recent --name ICMP_FLOOD --set -j REJECT --reject-with icmp-host-unreachable

# Layer 7 DDOS Protection
#------------------------------------------------------------------------------

# HTTP Flood Protection
$IPTABLES -A INPUT -p tcp --dport 80 -m string --string "GET /" --algo bm -m recent --name HTTP_FLOOD --set -j REJECT --reject-with tcp-reset
$IPTABLES -A INPUT -p tcp --dport 80 -m string --string "POST /" --algo bm -m recent --name HTTP_FLOOD --set -j REJECT --reject-with tcp-reset

# DNS Flood Protection
$IPTABLES -A INPUT -p udp --dport 53 -m string --string "ANY" --algo bm -m recent --name DNS_FLOOD --set -j REJECT --reject-with icmp-port-unreachable

# SSH Brute Force Protection
$IPTABLES -A INPUT -p tcp --dport 22 -m recent --name SSH_BRUTE --set -j REJECT --reject-with tcp-reset

# Other Protection
#------------------------------------------------------------------------------

# Drop invalid packets
$IPTABLES -A INPUT -m state --state INVALID -j DROP

# Drop packets with bogus TCP flags
$IPTABLES -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Drop packets with bogus UDP flags
$IPTABLES -A INPUT -p udp --udp-flags ALL ALL -j DROP

# Drop packets with bogus ICMP flags
$IPTABLES -A INPUT -p icmp --icmp-type ALL -j DROP

# Save and restart iptables
#------------------------------------------------------------------------------
service iptables save
service iptables restart

# Uninstall option
#------------------------------------------------------------------------------
UNINSTALL=0
if [ "$1" = "uninstall" ]; then
  UNINSTALL=1
fi

if [ $UNINSTALL -eq 1 ]; then
  # Remove all rules
  $IPTABLES -F
  $IPTABLES -X
  $IPTABLES -t nat -F
  $IPTABLES -t nat -X
  $IPTABLES -t mangle -F
  $IPTABLES -t mangle -X
  $IPTABLES -t raw -F
  $IPTABLES -t raw -X

  # Remove all chains
  $IPTABLES -X INPUT
  $IPTABLES -X OUTPUT
  $IPTABLES -X FORWARD
  $IPTABLES -t nat -X PR
