#!/bin/sh
#
# Bash编写的简单的Captive portal中用于处理用户超时的iptables清理
# 添加在crontab中定时执行
# 

# Date    : 2014-12-15
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

IPTABLES=/usr/sbin/iptables
VALID_USER_LOG=/tmp/validateuser.log
KNOWN_USER_LOG=/tmp/knownuser.log

VALIDATE_TIMEOUT=300  #认证中的清理时长，单位秒 5*60=300 5分钟
KNOWN_TIMEOUT=172800  #认证通过保持的时长，单位秒 2*24*60*60=172800 2天

nowtime=$(date +%s)
if [ -f $VALID_USER_LOG ]; then
	#处理认证中的用户清理
	while read LINE
	do
		mac=$(echo $LINE | awk -F" " '{print $1}')
		ip=$(echo $LINE | awk -F" " '{print $2}')
		timestamp=$(echo $LINE | awk -F" " '{print $3}')
		if [ $(($timestamp+$VALIDATE_TIMEOUT)) -lt $nowtime ]; then
			#超时处理
			$IPTABLES -t mangle -D chain_outgoing -s $REMOTE_ADDR -j MARK --set-mark 0x02
			$IPTABLES -t mangle -D chain_incoming -d $REMOTE_ADDR -j ACCEPT
			sed -i /$mac/d $VALID_USER_LOG
		else
			#用arp判断ip和mac地址是否对应，如果不一样则删除该条目
			arpmac=$(arp -a -n $ip |  awk -F " " '{ print $4 }' )
			if [ $arpmac != $mac ]; then
				$IPTABLES -t mangle -D chain_outgoing -s $REMOTE_ADDR -j MARK --set-mark 0x02
				$IPTABLES -t mangle -D chain_incoming -d $REMOTE_ADDR -j ACCEPT
				sed -i /$mac/d $VALID_USER_LOG
			fi
		fi

	done < $VALID_USER_LOG
fi

if [ -f $KNOWN_USER_LOG ]; then
	#处理认证通过的用户清理
	while read LINE
	do
		mac=$(echo $LINE | awk -F" " '{print $1}')
		ip=$(echo $LINE | awk -F" " '{print $2}')
		timestamp=$(echo $LINE | awk -F" " '{print $3}')
		if [ $(($timestamp+$KNOWN_TIMEOUT)) -lt $nowtime ]; then
			#用arp判断ip和mac地址是否对应，如果一样则更新延时
			arpmac=$(arp -a -n $ip |  awk -F " " '{ print $4 }' )
			if [ $arpmac = $mac ]; then  
				sed -i /$mac/d $KNOWN_USER_LOG
				echo "$mac $ip $nowtime" >> $KNOWN_USER_LOG
			else
				#超时处理
				sed -i /$mac/d $KNOWN_USER_LOG
				#删除iptables规则链，如果支持mac模块的话，加 -m mac --mac-source $mac 来限定更好
				$IPTABLES -t mangle -D chain_outgoing -s $ip -j MARK --set-mark 0x01
				$IPTABLES -t mangle -D chain_incoming -d $ip -j ACCEPT
			fi
		else
			#用arp判断ip和mac地址是否对应，如果不一样则删除该条目
			arpmac=$(arp -a -n $ip |  awk -F " " '{ print $4 }' )
			if [ $arpmac != $mac ]; then
				sed -i /$mac/d $KNOWN_USER_LOG
				#删除iptables规则链，如果支持mac模块的话，加 -m mac --mac-source $mac 来限定更好
				$IPTABLES -t mangle -D chain_outgoing -s $ip -j MARK --set-mark 0x01
				$IPTABLES -t mangle -D chain_incoming -d $ip -j ACCEPT
			fi
		fi

	done < $KNOWN_USER_LOG
fi

exit 0
        
