#!/bin/sh
#
# Bash编写的简单的Captive portal中部署在
# http服务器上的404页面用于处理各种操作
# 确保默认访问页面为404

# Date    : 2014-12-15
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

IPTABLES=/usr/sbin/iptables
CFG="default"
PORTAL_PORT="2060"
PORTAL_URL="http://auth.tgrass.com/index.action?"
AUTH_URL="http://auth.tgrass.com/auth.action?"
WELCOME_URL="http://auth.tgrass.com/welcome.action?"
VALID_USER_LOG="/tmp/val_${CFG}.log"
KNOWN_USER_LOG="/tmp/known_${CFG}.log"
interface="br-lan"

gw_address=$(ifconfig $interface | grep inet | cut -d : -f 2 | cut -d " " -f 1)
gw_mac=$(ifconfig $interface | grep HWaddr | awk -F " " '{ print $5 }')
gw_id=$(echo $gw_mac | awk -F ":" '{ print tolower($1$2$3$4$5$6) }')
user_ip=$REMOTE_ADDR
user_mac=$(cat /proc/net/arp | grep $user_ip | awk -F " " '{ print $4 }' )
timestamp=$(date +%s)

#模拟苹果系统返回success，以使得protal弹出页变成完成
apple_captive_resp(){
	echo "Content-type: text/html"
	echo ""
	echo '<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>'
}

#重定向到初始页面
redirect_index(){
	echo "Status: 302 Moved Temporarily"
	echo "Location: ${PORTAL_URL}gw_address=${gw_address}&gw_port=${PORTAL_PORT}&gw_id=${gw_id}&mac=${user_mac}&url="
	echo ""
}

redirect_welcome(){
	echo "Status: 302 Moved Temporarily"
	echo "Location: ${WELCOME_URL}gw_address=${gw_address}&gw_port=${PORTAL_PORT}&gw_id=${gw_id}&mac=${user_mac}&url="
	echo ""
}

#portal弹出页面
portal_show(){
	redirect_index
}

#远程验证是否允许访问
check_auth(){
	wget -q -U "${HTTP_USER_AGENT}" -O - "${AUTH_URL}stage=login&gw_address=${gw_address}&gw_port=${PORTAL_PORT}&gw_id=${gw_id}&mac=${user_mac}" | grep "Auth:" | awk -F " " '{print $2}'
}

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

proc_iptables(){
#远程验证是否允许访问
	local authret=$(wget -q -U "${HTTP_USER_AGENT}" -O - "${AUTH_URL}stage=login&gw_address=${gw_address}&gw_port=${PORTAL_PORT}&gw_id=${gw_id}&mac=${user_mac}" | grep "Auth:" | awk -F " " '{print $2}')
	if [ $authret -eq 5 ]; then
		#服务器返回认证中
		clear_known_flag $user_ip $user_mac
		set_valid_flag $user_ip $user_mac
	elif [ $authret -eq 1 ]; then
		#服务器返回认证通过
		clear_valid_flag $user_ip $user_mac
		set_known_flag $user_ip $user_mac
	else
		clear_valid_flag $user_ip $user_mac
		clear_known_flag $user_ip $user_mac
	fi

	echo "Content-type: text/html"
	echo ""
	echo "{success:true}"
}

#/checkimg.png 是一个嵌入在portal页里的元素，用来保证portal页已经弹出过了
if [ $REQUEST_URI = "/checkimg.png" ]; then
	set_valid_flag $user_ip $user_mac
elif [ $HTTP_HOST = "i.tgrass.com:${PORTAL_PORT}" ]; then
	proc_iptables
elif [ $HTTP_HOST = "${gw_address}:${PORTAL_PORT}" ]; then
	proc_iptables
else
	if [ -f $VALID_USER_LOG ]; then
		local num=$(grep $user_mac $VALID_USER_LOG | wc -l)
		if [ $num -gt 0 ]; then
			local apple_captive_host="www.apple.com|www.appleiphonecell.com|captive.apple.com|www.itools.info|www.ibook.info|www.airport.us|www.thinkdifferent.us"
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
	else
		portal_show
	fi
fi

exit 0
        
