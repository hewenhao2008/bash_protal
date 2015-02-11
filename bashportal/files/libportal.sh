#!/bin/sh
#
# 公共函数
#

# Date    : 2014-12-15
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

#清除认证中标志
clear_valid_flag(){
	local mac=$1
	local ip=$2
	local LINE imac iip
	if [ -n "$mac" -a -f "$VALID_USER_LOG" ]; then
		grep "$mac" $VALID_USER_LOG | while read LINE
		do
			imac=$(echo $LINE | awk -F" " '{print $1}')
			iip=$(echo $LINE | awk -F" " '{print $2}')
			if [ -z "$ip" -o "$ip" != "$iip" ]; then
				$IPTABLES -t mangle -D bp_${CFG}_outgoing -s $iip -m mac --mac-source $imac -j MARK --set-mark 0x02
				$IPTABLES -t mangle -D bp_${CFG}_incoming -d $iip -j ACCEPT
			fi
			sed -i "/$imac $iip/d" $VALID_USER_LOG
		done
	fi
}

#设置用户为认证中状态
set_valid_flag(){
	local mac=$1
	local ip=$2
	local timestamp=$(date +%s)
	clear_valid_flag $mac $ip
	local num=$(grep "$mac $ip" $VALID_USER_LOG | wc -l)
	if [ $num -le 0 ]; then
		$IPTABLES -t mangle -A bp_${CFG}_outgoing -s $ip -m mac --mac-source $mac -j MARK --set-mark 0x02
		$IPTABLES -t mangle -A bp_${CFG}_incoming -d $ip -j ACCEPT
		echo "$mac $ip $timestamp" >> $VALID_USER_LOG
	fi
}

#清除认证通过标志
clear_known_flag(){
	local mac=$1
	local ip=$2
	local LINE imac iip
	if [ -n "$mac" -a -f "$KNOWN_USER_LOG" ]; then
		grep "$mac" $KNOWN_USER_LOG | while read LINE
		do
			imac=$(echo $LINE | awk -F" " '{print $1}')
			iip=$(echo $LINE | awk -F" " '{print $2}')
			if [ -z "$ip" -o "$ip" != "$iip" ]; then
				$IPTABLES -t mangle -D bp_${CFG}_outgoing -s $iip -m mac --mac-source $imac -j MARK --set-mark 0x01
				$IPTABLES -t mangle -D bp_${CFG}_incoming -d $iip -j ACCEPT
			fi
			sed -i "/$imac $iip/d" $KNOWN_USER_LOG
		done
	fi
}

#设置用户为认证通过
set_known_flag(){
	local mac=$1
	local ip=$2
	clear_known_flag $mac $ip
	local num=$(grep "$mac $ip" $VALID_USER_LOG | wc -l)
	if [ $num -le 0 ]; then
		$IPTABLES -t mangle -A bp_${CFG}_outgoing -s $ip -m mac --mac-source $mac -j MARK --set-mark 0x01
		$IPTABLES -t mangle -A bp_${CFG}_incoming -d $ip -j ACCEPT
		echo "$mac $ip" >> $KNOWN_USER_LOG
	fi
}

#远程验证是否允许访问
proc_iptables(){
	local mac=$1
	local ip=$2
	local hostname=$3
	local authret=$(wget -q -U "${HTTP_USER_AGENT}" -O - "${AUTH_URL}stage=login&gw_address=${GW_ADDRESS}&gw_port=${PORTAL_PORT}&gw_id=${GW_ID}&mac=${mac}&hostname=${hostname}" | grep "Auth:" | awk -F " " '{print $2}')
	if [ $authret -eq 5 ]; then
		#服务器返回认证中
		clear_known_flag $mac
		set_valid_flag $mac $ip
	elif [ $authret -eq 1 ]; then
		#服务器返回认证通过
		clear_valid_flag $mac
		set_known_flag $mac $ip
	else
		clear_valid_flag $mac
		clear_known_flag $mac
	fi
}

