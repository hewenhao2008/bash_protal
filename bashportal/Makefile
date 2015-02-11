#
# Copyright (C) 2015 czhongm <czhongm@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=BashPortal
PKG_VERSION:=$(shell git --git-dir=$(CURDIR)/../.git log -1 --pretty="%ci %h" | awk '{ print $$1 "-" $$4 }')
PKG_MAINTAINER:=czhongm <czhongm@gmail.com>
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/BashPortal
  SECTION:=BashPortal
  CATEGORY:=TGrass
  TITLE:=Bash Portal
  DEPENDS:=+iptables-mod-extra +iptables-mod-ipopt +kmod-ipt-nat +iptables-mod-nat-extra +uhttpd
endef

define Package/BashPortal/description
 Captive portal solution by use bash shell.
endef

define Package/BashPortal/conffiles
/etc/config/bashportal
endef

define Build/Compile
endef

define Package/BashPortal/install
	$(INSTALL_DIR) $(1)/tgrass/portal
	$(INSTALL_BIN) ./files/bashportal.cgi $(1)/tgrass/portal/bashportal.cgi
	$(INSTALL_BIN) ./files/libportal.sh $(1)/tgrass/portal/libportal.sh
	$(INSTALL_BIN) ./files/dhcplistener.sh $(1)/tgrass/dhcplistener.sh
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/bashportal.conf $(1)/etc/config/bashportal
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/bashportal.init $(1)/etc/init.d/bashportal
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/trustip $(1)/etc/trustip
	$(INSTALL_DATA) ./files/trustmac $(1)/etc/trustmac
endef

define Package/BashPortal/postinst
#!/bin/sh

uci set dhcp.@dnsmasq[0].dhcpscript="/tgrass/dhcplistener.sh"
uci commit dhcp

exit 0
endef

$(eval $(call BuildPackage,BashPortal))
