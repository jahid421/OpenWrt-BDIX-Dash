#!/bin/sh

echo "========================================================"
echo "    BDIX BYPASS - FULL UNINSTALLER & CLEANER            "
echo "    Developed by: Jahid Hasan Shuvo (@crazy_boy_jahid)  "
echo "========================================================"

# [1] Service Stop and Disabling
echo -e "\nStopping and disabling services..."
/etc/init.d/redsocks stop 2>/dev/null
/etc/init.d/redsocks disable 2>/dev/null

# [2] Main File Remove
echo "Removing binary and config files..."
rm -f /etc/init.d/redsocks
rm -f /etc/redsocks.conf
rm -f /usr/share/luci/menu.d/luci-app-redsocks.json
rm -rf /usr/lib/lua/luci/view/redsocks/
rm -f /www/cgi-bin/redsocks_ctl

# [3] (Iptables) Rules and Navigation Rules Cleanup
echo "Cleaning Iptables and network rules..."
iptables -t nat -D PREROUTING -p tcp -i br-lan -j REDSOCKS 2>/dev/null
iptables -t nat -F REDSOCKS 2>/dev/null
iptables -t nat -X REDSOCKS 2>/dev/null

# [4] Cache file and LuCI cache (Deep Cleaning)
echo "Clearing system and LuCI cache..."
rm -rf /tmp/luci-indexcache
rm -rf /tmp/luci-modulecache/*
rm -rf /tmp/luci-statcache

# [5] UI Restart
echo "Restarting web interface services..."
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "========================================================"
echo "    CLEANUP COMPLETE! BDIX BYPASS REMOVED COMPLETELY.   "
echo "========================================================"
