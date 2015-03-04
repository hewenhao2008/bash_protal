#!/bin/sh
#
# Bash编写的用于处理dnsmasq分配ip地址时触发认证处理
# 添加在dnsmasq
# 

# Date    : 2015-01-27
# Version : 1.0
# Author  : czhongm <czhongm@gmail.com>

if [ -f /tmp/portal/${DNSMASQ_INTERFACE}.sh ]; then
	/tmp/portal/${DNSMASQ_INTERFACE}.sh $1 $2 $3 $4
fi

exit 0
        
