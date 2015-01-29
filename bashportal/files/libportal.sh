#!/bin/sh
#
# 公共函数
#

# Date    : 2014-12-15
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

#设置用户为认证中状态
set_valid_flag(){
	local ip=$1
	local mac=$2
	local recflag=0
	if [ -f $VALID_USER_LOG ]; then
		local num=$(grep $mac $VALID_USER_LOG | wc -l)
		if [ $num -ge 1 ]; then
			recflag=1
		fi
	fi
	if [ $recflag -eq 0 ]; then
		$IPTABLES -t mangle -A bp_${CFG}_outgoing -s $ip -m mac --mac-source $mac -j MARK --set-mark 0x02
		$IPTABLES -t mangle -A bp_${CFG}_incoming -d $ip -j ACCEPT
		echo "$mac $ip $timestamp" >> $VALID_USER_LOG
	fi
}

#清除认证中标志
clear_valid_flag(){
	local ip=$1
	local mac=$2
	local recflag=0
	if [ -f $VALID_USER_LOG ]; then
		local num=$(grep $mac $VALID_USER_LOG | wc -l)
		if [ $num -ge 1 ]; then
			recflag=1
		fi
	fi
	if [ $recflag -eq 1 ]; then
		$IPTABLES -t mangle -D bp_${CFG}_outgoing -s $ip -m mac --mac-source $mac -j MARK --set-mark 0x02
		$IPTABLES -t mangle -D bp_${CFG}_incoming -d $ip -j ACCEPT
		sed -i "/$mac/d" $VALID_USER_LOG
	fi
}

#设置用户为认证通过
set_known_flag(){
	local ip=$1
	local mac=$2
	local recflag=0
	if [ -f $KNOWN_USER_LOG ]; then
		local num=$(grep $mac $KNOWN_USER_LOG | wc -l)
		if [ $num -ge 1 ]; then
			recflag=1
		fi
	fi
	if [ $recflag -eq 0 ]; then
		$IPTABLES -t mangle -A bp_${CFG}_outgoing -s $ip -m mac --mac-source $mac -j MARK --set-mark 0x01
		$IPTABLES -t mangle -A bp_${CFG}_incoming -d $ip -j ACCEPT
		echo "$mac $ip $timestamp" >> $KNOWN_USER_LOG
	fi
}

#清除认证通过标志
clear_known_flag(){
	local ip=$1
	local mac=$2
	local recflag=0
	if [ -f $KNOWN_USER_LOG ]; then
		local num=$(grep $mac $KNOWN_USER_LOG | wc -l)
		if [ $num -ge 1 ]; then
			recflag=1
		fi
	fi
	if [ $recflag -eq 1 ]; then
		$IPTABLES -t mangle -D bp_${CFG}_outgoing -s $ip -m mac --mac-source $mac -j MARK --set-mark 0x01
		$IPTABLES -t mangle -D bp_${CFG}_incoming -d $ip -j ACCEPT
		sed -i "/$mac/d" $KNOWN_USER_LOG
	fi
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

