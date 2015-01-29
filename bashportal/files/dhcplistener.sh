#!/bin/sh
#
# Bash编写的用于处理dnsmasq分配ip地址时触发认证处理
# 添加在dnsmasq
# 

# Date    : 2015-01-27
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

IPTABLES=/usr/sbin/iptables

. /tgrass/libportal.sh

action=$1
mac=$2
ip=$3
hostname=$4

if [ $action = "add" -o $action = "old" ]; then
	
elif [ $action = "del" ]; then
	clear_valid_flag $ip $mac
	clear_known_flag $ip $mac
fi

exit 0
        
