#!/bin/sh
#
# Bash编写的用于处理dnsmasq分配ip地址时触发认证处理
# 添加在dnsmasq
# 

# Date    : 2015-01-27
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

IPTABLES=/usr/sbin/iptables

. $IPKG_INSTROOT/lib/functions.sh

action=$1
mac=$2
ip=$3
hostname=$4

auth_client(){
	local cfg="$1"
	local interface extinterface trustfile validfile ip validlog knownlog mac portalport
	local portal_url auth_url welcome_url
	local gw_address gw_mac gw_id
	config_get interface "$cfg" interface
	if [ $DNSMASQ_INTERFACE = $interface ]; then
		. /tmp/portal/$cfg/env.sh
		. /tgrass/portal/libportal.sh
		if [ $action = "add" -o $action = "old" ]; then
			proc_iptables $ip $mac
		elif [ $action = "del" ]; then
			clear_valid_flag $ip $mac
			clear_known_flag $ip $mac
		fi
	fi
}

config_load bashportal
config_foreach auth_client portal

exit 0
        
