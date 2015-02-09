#!/bin/sh
#
# 公共函数
#

# Date    : 2014-12-15
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

#清除认证中标志
clear_valid_flag(){
	local ip=$1
	local mac=$2
	local LINE i_mac i_ip
	if [ -f $VALID_USER_LOG ]; then
		while read LINE
		do
			i_mac=$(echo $LINE | awk -F" " '{print $1}')
			i_ip=$(echo $LINE | awk -F" " '{print $2}')
			if [ $i_mac = $mac ]; then
				$IPTABLES -t mangle -D bp_${CFG}_outgoing -s $i_ip -m mac --mac-source $i_mac -j MARK --set-mark 0x02
				$IPTABLES -t mangle -D bp_${CFG}_incoming -d $i_ip -j ACCEPT
			fi
		done < $VALID_USER_LOG
		sed -i "/$mac/d" $VALID_USER_LOG
	fi
}

#设置用户为认证中状态
set_valid_flag(){
	local ip=$1
	local mac=$2
	local timestamp=$(date +%s)
	clear_valid_flag
	$IPTABLES -t mangle -A bp_${CFG}_outgoing -s $ip -m mac --mac-source $mac -j MARK --set-mark 0x02
	$IPTABLES -t mangle -A bp_${CFG}_incoming -d $ip -j ACCEPT
	echo "$mac $ip $timestamp" >> $VALID_USER_LOG
}

#清除认证通过标志
clear_known_flag(){
	local ip=$1
	local mac=$2
	local LINE i_mac i_ip
	if [ -f $KNOWN_USER_LOG ]; then
		while read LINE
		do
			i_mac=$(echo $LINE | awk -F" " '{print $1}')
			i_ip=$(echo $LINE | awk -F" " '{print $2}')
			if [ $i_mac = $mac ]; then
				$IPTABLES -t mangle -D bp_${CFG}_outgoing -s $i_ip -m mac --mac-source $i_mac -j MARK --set-mark 0x01
				$IPTABLES -t mangle -D bp_${CFG}_incoming -d $i_ip -j ACCEPT
			fi
		done < $KNOWN_USER_LOG
		sed -i "/$mac/d" $KNOWN_USER_LOG
	fi
}

#设置用户为认证通过
set_known_flag(){
	local ip=$1
	local mac=$2
	local timestamp=$(date +%s)
	clear_known_flag
	$IPTABLES -t mangle -A bp_${CFG}_outgoing -s $ip -m mac --mac-source $mac -j MARK --set-mark 0x01
	$IPTABLES -t mangle -A bp_${CFG}_incoming -d $ip -j ACCEPT
	echo "$mac $ip $timestamp" >> $KNOWN_USER_LOG
}

#远程验证是否允许访问
proc_iptables(){
	local ip=$1
	local mac=$2
	local authret=$(wget -q -U "${HTTP_USER_AGENT}" -O - "${AUTH_URL}stage=login&gw_address=${GW_ADDRESS}&gw_port=${PORTAL_PORT}&gw_id=${GW_ID}&mac=${mac}" | grep "Auth:" | awk -F " " '{print $2}')
	if [ $authret -eq 5 ]; then
		#服务器返回认证中
		clear_known_flag $ip $mac
		set_valid_flag $ip $mac
	elif [ $authret -eq 1 ]; then
		#服务器返回认证通过
		clear_valid_flag $ip $mac
		set_known_flag $ip $mac
	else
		clear_valid_flag $ip $mac
		clear_known_flag $ip $mac
	fi
}

