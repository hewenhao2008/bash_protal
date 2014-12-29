#!/bin/sh
#
# Bash编写的简单的Captive portal中部署在
# http服务器上的404页面用于处理各种操作
# 确保默认访问页面为404

# Date    : 2014-12-15
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

IPTABLES=/usr/sbin/iptables
PORTAL_HTML=/userdisk/tgrass/bash_protal/html/index.html
VALID_USER_LOG=/tmp/validateuser.log
KNOWN_USER_LOG=/tmp/knownuser.log

#模拟苹果系统返回success，以使得protal弹出页变成完成
apple_captive_resp(){
	echo "Content-type: text/html"
	echo ""
	echo '<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>'
}

#portal弹出页面
portal_show(){
	echo "Content-type:text/html"
	echo ""
	cat $PORTAL_HTML
}

env >> /tmp/tmp.log

mac=$(arp -a -n $REMOTE_ADDR |  awk -F " " '{ print $4 }' )
timestamp=$(date +%s)
#/checkimg.png 是一个嵌入在portal页里的元素，用来保证portal页已经弹出过了
if [ $REQUEST_URI = "/checkimg.png" ]; then
	if [ -f $VALID_USER_LOG ]; then
		num=$(grep $mac $VALID_USER_LOG | wc -l)
		if [ $num -lt 1 ]; then
			$IPTABLES -t mangle -A chain_outgoing -s $REMOTE_ADDR -j MARK --set-mark 0x02
			$IPTABLES -t mangle -A chain_incoming -d $REMOTE_ADDR -j ACCEPT
			echo "$mac $REMOTE_ADDR $timestamp" >> $VALID_USER_LOG
		fi
	else
		$IPTABLES -t mangle -A chain_outgoing -s $REMOTE_ADDR -j MARK --set-mark 0x02
		$IPTABLES -t mangle -A chain_incoming -d $REMOTE_ADDR -j ACCEPT
		echo "$mac $REMOTE_ADDR $timestamp" >> $VALID_USER_LOG
	fi
elif [ $HTTP_HOST = "i.tgrass.com:2060" ]; then
#	if [ ${REQUEST_URI:1:8} = "/app.gif" ]; then
		#是否通过服务器来认证？暂时直接放行
	#删除/tmp/avlidateuser.log中对应的项
	
	sed -i "/$mac/d" $VALID_USER_LOG
	$IPTABLES -t mangle -D chain_outgoing -s $REMOTE_ADDR -j MARK --set-mark 0x02
	$IPTABLES -t mangle -D chain_incoming -d $REMOTE_ADDR -j ACCEPT
	#因为没有MAC模块支持，所以只限定ip地址,如果支持mac模块的话，加 -m mac --mac-source $mac 来限定更好
	if [ -f $KNOWN_USER_LOG ]; then
		num=$(grep $mac $KNOWN_USER_LOG | wc -l)
		if [ $num -lt 1 ]; then
			$IPTABLES -t mangle -A chain_outgoing -s $REMOTE_ADDR -j MARK --set-mark 0x01
			$IPTABLES -t mangle -A chain_incoming -d $REMOTE_ADDR -j ACCEPT
			echo "$mac $REMOTE_ADDR $timestamp" >> $KNOWN_USER_LOG
		fi
	else
		$IPTABLES -t mangle -A chain_outgoing -s $REMOTE_ADDR -j MARK --set-mark 0x01
		$IPTABLES -t mangle -A chain_incoming -d $REMOTE_ADDR -j ACCEPT
		echo "$mac $REMOTE_ADDR $timestamp" >> $KNOWN_USER_LOG
	fi

	echo "Content-type: text/html"
	echo ""
	echo "{success:true}"
#	fi
else
	num=$(grep $mac $VALID_USER_LOG | wc -l)
	if [ $num -gt 0 ]; then
		apple_captive_host="www.apple.com|www.appleiphonecell.com|captive.apple.com|www.itools.info|www.ibook.info|www.airport.us|www.thinkdifferent.us"
		case $apple_captive_host in 
		    *"$HTTP_HOST"*)  
			apple_captive_resp
			;;
		    *) 
			portal_show
			;;
		esac
	else
		portal_show
	fi	
fi

exit 0
        
