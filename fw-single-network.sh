#! /bin/bash
# ************************************************************
# *           -=- Configuracao do FIREWALL -=-               *
# *                                                          *
# *  Criado por:   Cleber Paiva de Souza                     *
# *  Ultima Mod.:  31/10/2021                                *
# *                                                          *
# * Adaptadores de Rede                                      *
# * -------------------                                      *
# *                                                          *
# * eth0: rede interna (192.168.1.1)                         *
# *                                                          *
# ************************************************************

IPTABLES="$(which iptables)"

IF_INT="eth0"
LAN_INT="192.168.10.0/24"
ME_INT="192.168.1.1"

LAN_ALL="0.0.0.0/0"
SERVICES_TCP_INT="22"
SERVICES_UDP_INT="67,68"

# Flush iptables counts and rules
for table in filter nat mangle
do
	echo "Flushing table $table..."
	$IPTABLES -t $table -F
	$IPTABLES -t $table -X
	$IPTABLES -t $table -Z
done

# Setting default policies for tables
echo "Setting default rules..."
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT

# Allow loopback
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# Block IP Spoofing
echo "Blocking IP Spoofing from well-know networks..."
$IPTABLES -A INPUT -i $IF_INT -s 127.0.0.0/8 -j DROP
$IPTABLES -A INPUT -i $IF_INT -s 169.254.0.0/16 -j DROP
$IPTABLES -A INPUT -i $IF_INT -s 172.16.0.0/12 -j DROP
$IPTABLES -A INPUT -i $IF_INT -s 10.0.0.0/8 -j DROP
$IPTABLES -A INPUT -i $IF_INT -s 192.0.2.0/24 -j DROP
$IPTABLES -A INPUT -i $IF_INT -s 240.0.0.0/4 -j DROP

# Keep connection states and allow only related connections
echo "Applying Iptables rules..."
$IPTABLES -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -i $IF_INT -j ACCEPT

# Ping ICMP
$IPTABLES -A INPUT -i $IF_INT -p icmp -s $LAN_INT -d $ME_INT -m limit --limit 5/s -j ACCEPT

# Allow services
[ ${#SERVICES_TCP_INT} -gt 0 ] && \
    $IPTABLES -A INPUT -i $IF_INT -p tcp -s $LAN_INT -d $ME_INT \
    -m multiport --dports ${SERVICES_TCP_INT} -m conntrack --ctstate NEW --syn -j ACCEPT
[ ${#SERVICES_UDP_INT} -gt 0 ] && \
    $IPTABLES -A INPUT -i $IF_INT -p udp -s $LAN_INT -d $ME_INT \
    -m multiport --dports ${SERVICES_UDP_INT} -m conntrack --ctstate NEW -j ACCEPT

# Block everything else
$IPTABLES -A INPUT -j DROP
$IPTABLES -A FORWARD -j DROP
