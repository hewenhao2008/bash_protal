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
