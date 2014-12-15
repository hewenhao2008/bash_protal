#!/bin/sh

IPTABLES=/usr/sbin/iptables

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
	echo '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><meta  charset="utf-8">
<link  href="/images/wifi.css"  rel="stylesheet"  type="text/css">
<script  src="/images/jquery-1.9.1.min.js"></script>
    <script  src="/images/owl.carousel.min.js"></script>
    <script  src="/images/detectClient.js"></script>
    <link  href="/images/owl.carousel.css"  rel="stylesheet">
    <link  href="/images/owl.theme.css"  rel="stylesheet">
    <script  src="/images/idangerous.swiper-1.9.1.min.js"></script>
    <script  src="/images/idangerous.swiper.scrollbar-1.2.js"></script>
  <script  src="/images/swiper-demos.js"></script>
<meta  content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0;"  name="viewport">
<meta  content="yes"  name="apple-mobile-web-app-capable">
<meta  content="black"  name="apple-mobile-web-app-status-bar-style">
<meta  content="telephone=no"  name="format-detection">
<meta  content="email=no"  name="format-detection">
<title>wifi展页</title>
</head><body><div  id="appframe2">
<article  class="box"  id="contentBox"  style="top: 0px;">
<div  class="heads posit biaoti"  id="biaotilan"  style="display: block;">
<p><a><input  class="edtoput"  name="aaa"  id="aaa"  type="text"  value="小草网赚免费WIFI"  disabled="disabled"></a></p>
</div>
<div  class="headbg">
<div  class="head">
<img  src="/images/head_title.jpg"  width="100%">
<p>1. 下载并安装小草网赚APP<br>
2. 打开小草网赚APP</p>
<div  class="last_text"><div  class="last_t_img"><img  src="/images/head_icon.jpg"></div>以后每次上网，请先打开小草网赚APP</div>
</div>
</div>
<img src="/checkimg.png" width="1" height="1" />
<div  class="text_box"  id="hangyeyonghu">
<div  class="wfplace">
<div  class="pagination pagination1"><span  class="swiper-pagination-switch swiper-active-switch swiper-activeslide-switch"></span><span  class="swiper-pagination-switch"></span><span  class="swiper-pagination-switch"></span><span  class="swiper-pagination-switch"></span><span  class="swiper-pagination-switch"></span><span  class="swiper-pagination-switch"></span></div></div></div>
<div  class="box1">
  <img  src="/images/content_img.jpg"  width="100%">
</div>
</article>
<div  id="bottomToolbar"><a  class="pie_radius3"  href="https://i.tgrass.com/files/android.apk"><img  src="/images/android_download.jpg"  width="140"  height="40"></a>
    <a  class="pie_radius4"  href="itms-services://?action=download-manifest&url=https://i.tgrass.com/files/ios_hs.plist"><img  src="/images/ios_download.jpg"  width="140"  height="40"></a></div></div></body></html>'
}

	echo  $HTTP_HOST >> /tmp/temp.log

mac=$(arp -a $REMOTE_ADDR |  awk -F " " '{ print $4 }' )
if [ $REQUEST_URI = "/checkimg.png" ]; then
	if [ -f /tmp/validateuser.log ]; then
		num=$(grep $mac /tmp/validateuser.log | wc -l)
		if [ $num -lt 1 ]; then
			echo $mac >> /tmp/validateuser.log
		fi
	else
		echo $mac >> /tmp/validateuser.log
	fi
elif [ $HTTP_HOST = "i.tgrass.com:2060" ]; then
#	if [ ${REQUEST_URI:1:8} = "/app.gif" ]; then
		#是否通过服务器来认证？暂时直接放行
	#echo "$IPTABLES -t mangle  -I internet 1 -m mac --mac-source $mac -j RETURN" > /tmp/1.log
	$IPTABLES -t mangle -A chain_outgoing -s $REMOTE_ADDR -j MARK --set-mark 0x01
	$IPTABLES -t mangle -A chain_incoming -d $REMOTE_ADDR -j ACCEPT

	echo "Content-type: text/html"
	echo ""
	echo "{success:true}"
#	fi
else
	num=$(grep $mac /tmp/validateuser.log | wc -l)
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
        
