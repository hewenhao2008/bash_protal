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

include $(INCLUDE_DIR)/package.mk

define Package/BashPortal
  SECTION:=BashPortal
  CATEGORY:=TGrass
  TITLE:=Bash Portal
  DEPENDS:=+iptables-mod-extra +iptables-mod-ipopt +kmod-ipt-nat +iptables-mod-nat-extra +uhttpd +uhttpd-mod-ubus
endef

define Package/BashPortal/description
 Captive portal solution by use bash shell.
endef

define Package/BashPortal/conffiles
/etc/config/bashportal
endef

define Package/BashPortal/install
	$(INSTALL_DIR) $(1)/www
	$(CP) ./htdocs/* $(1)/www/
	$(INSTALL_DIR) $(1)/usr/share/rpcd
	$(CP) ./share/* $(1)/usr/share/rpcd/
	$(INSTALL_DIR) $(1)/usr/lib/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rpcd/luci2.so $(1)/usr/lib/rpcd/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rpcd/bwmon.so $(1)/usr/lib/rpcd/
	$(INSTALL_DIR) $(1)/usr/libexec $(1)/www/cgi-bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/io/luci2-io $(1)/usr/libexec/
	$(LN) /usr/libexec/luci2-io $(1)/www/cgi-bin/luci-upload
	$(LN) /usr/libexec/luci2-io $(1)/www/cgi-bin/luci-backup
endef

define Package/luci2/postinst
#!/bin/sh

if [ "$$(uci -q get uhttpd.main.ubus_prefix)" != "/ubus" ]; then
	uci set uhttpd.main.ubus_prefix="/ubus"
	uci commit uhttpd
fi

exit 0
endef

$(eval $(call BuildPackage,BashPortal))
