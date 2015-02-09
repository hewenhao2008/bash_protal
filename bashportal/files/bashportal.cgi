#!/bin/sh

user_ip=$REMOTE_ADDR
user_mac=$(cat /proc/net/arp | grep $user_ip | awk -F " " '{ print $4 }' )

#模拟苹果系统返回success，以使得protal弹出页变成完成
apple_captive_resp(){
	echo "Content-type: text/html"
	echo ""
	echo '<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>'
}

#重定向到初始页面
redirect_index(){
	echo "Status: 302 Moved Temporarily"
	echo "Location: ${PORTAL_URL}gw_address=${GW_ADDRESS}&gw_port=${PORTAL_PORT}&gw_id=${GW_ID}&mac=${user_mac}&url="
	echo ""
}

redirect_welcome(){
	echo "Status: 302 Moved Temporarily"
	echo "Location: ${WELCOME_URL}gw_address=${GW_ADDRESS}&gw_port=${PORTAL_PORT}&gw_id=${GW_ID}&mac=${user_mac}&url="
	echo ""
}

#portal弹出页面
portal_show(){
	redirect_index
}

#/checkimg.png 是一个嵌入在portal页里的元素，用来保证portal页已经弹出过了
if [ $REQUEST_URI = "/checkimg.png" ]; then
	set_valid_flag $user_ip $user_mac
elif [ $HTTP_HOST = "i.tgrass.com:${PORTAL_PORT}" ]; then
	proc_iptables $user_ip $user_mac
	apple_captive_resp
elif [ $HTTP_HOST = "${GW_ADDRESS}:${PORTAL_PORT}" ]; then
	proc_iptables $user_ip $user_mac
	apple_captive_resp
else
	if [ -f $VALID_USER_LOG ]; then
		local num=$(grep "$user_mac $user_ip" $VALID_USER_LOG | wc -l)
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
        
