#!/bin/sh

echo "========================================================"
echo "          UNINSTALLING BDIX BYPASS...                   "
echo "========================================================"

# ১. Service Stop process
/etc/init.d/redsocks stop
/etc/init.d/redsocks disable

# ২. Removing Service and config
rm -f /etc/init.d/redsocks
rm -f /etc/redsocks.conf

# ৩. UI File and menu Remove
rm -f /usr/share/luci/menu.d/luci-app-redsocks.json
rm -rf /usr/lib/lua/luci/view/redsocks/
rm -f /www/cgi-bin/redsocks_ctl

# ৪. Packeg removing
# opkg remove redsocks iptables-mod-nat-extra

# ৫. Cache and UI restart
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/*
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "========================================================"
echo "    UNINSTALL COMPLETE! System is clean now.            "
echo "========================================================"