#!/bin/sh

echo "========================================================"
echo "    BDIX BYPASS - FULL UNINSTALLER & CLEANER v2.0       "
echo "    Developed by: Jahid Hasan Shuvo (@crazy_boy_jahid)  "
echo "========================================================"
sleep 1

# [1/6] Service Stop and Disable
echo -e "\n[1/6] Stopping and disabling services..."
if [ -f /var/run/redsocks.pid ]; then
    kill $(cat /var/run/redsocks.pid) 2>/dev/null
    rm -f /var/run/redsocks.pid
    echo "  ✓ Redsocks process killed"
else
    echo "  ✓ Redsocks was not running"
fi
/etc/init.d/redsocks stop 2>/dev/null
/etc/init.d/redsocks disable 2>/dev/null
echo "  ✓ Service disabled from boot"

# [2/6] IPTables Rules Cleanup
echo -e "\n[2/6] Cleaning IPTables rules..."
iptables -t nat -D PREROUTING -p tcp -i br-lan -j REDSOCKS 2>/dev/null
iptables -t nat -F REDSOCKS 2>/dev/null
iptables -t nat -X REDSOCKS 2>/dev/null
echo "  ✓ REDSOCKS chain removed"
echo "  ✓ PREROUTING rule removed"
echo "  ✓ NAT rules cleaned"

# [3/6] Config & Init Files Remove
echo -e "\n[3/6] Removing config and init files..."
rm -f /etc/init.d/redsocks && echo "  ✓ /etc/init.d/redsocks removed" || echo "  - Not found (skipped)"
rm -f /etc/redsocks.conf && echo "  ✓ /etc/redsocks.conf removed" || echo "  - Not found (skipped)"

# [4/6] LuCI UI Files Remove
echo -e "\n[4/6] Removing LuCI UI files..."
rm -f /usr/share/luci/menu.d/luci-app-redsocks.json && echo "  ✓ Menu config removed" || echo "  - Not found (skipped)"
rm -rf /usr/lib/lua/luci/view/redsocks/ && echo "  ✓ UI template removed" || echo "  - Not found (skipped)"
rm -f /usr/lib/lua/luci/controller/redsocks.lua && echo "  ✓ Controller removed" || echo "  - Not found (skipped)"
rm -f /www/cgi-bin/redsocks_ctl && echo "  ✓ CGI handler removed" || echo "  - Not found (skipped)"

# [5/6] Cache Deep Clean
echo -e "\n[5/6] Deep cleaning cache..."
rm -rf /tmp/luci-indexcache && echo "  ✓ luci-indexcache cleared"
rm -rf /tmp/luci-modulecache/* && echo "  ✓ luci-modulecache cleared"
rm -rf /tmp/luci-statcache && echo "  ✓ luci-statcache cleared"
rm -rf /tmp/luci-sessions/* 2>/dev/null && echo "  ✓ luci-sessions cleared"

# [6/6] Service Restart & Verify
echo -e "\n[6/6] Restarting services & verifying..."
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart
echo ""

echo "────────────────────────────────────────"
echo "  VERIFICATION REPORT"
echo "────────────────────────────────────────"

PASS=0
FAIL=0

# Check each file
if [ ! -f /etc/redsocks.conf ]; then
    echo "  ✅ Config file        - REMOVED"
    PASS=$((PASS+1))
else
    echo "  ❌ Config file        - STILL EXISTS"
    FAIL=$((FAIL+1))
fi

if [ ! -f /etc/init.d/redsocks ]; then
    echo "  ✅ Init script        - REMOVED"
    PASS=$((PASS+1))
else
    echo "  ❌ Init script        - STILL EXISTS"
    FAIL=$((FAIL+1))
fi

if [ ! -f /usr/share/luci/menu.d/luci-app-redsocks.json ]; then
    echo "  ✅ Menu config        - REMOVED"
    PASS=$((PASS+1))
else
    echo "  ❌ Menu config        - STILL EXISTS"
    FAIL=$((FAIL+1))
fi

if [ ! -d /usr/lib/lua/luci/view/redsocks/ ]; then
    echo "  ✅ UI template        - REMOVED"
    PASS=$((PASS+1))
else
    echo "  ❌ UI template        - STILL EXISTS"
    FAIL=$((FAIL+1))
fi

if [ ! -f /www/cgi-bin/redsocks_ctl ]; then
    echo "  ✅ CGI handler        - REMOVED"
    PASS=$((PASS+1))
else
    echo "  ❌ CGI handler        - STILL EXISTS"
    FAIL=$((FAIL+1))
fi

if [ ! -f /var/run/redsocks.pid ]; then
    echo "  ✅ PID file           - REMOVED"
    PASS=$((PASS+1))
else
    echo "  ❌ PID file           - STILL EXISTS"
    FAIL=$((FAIL+1))
fi

# IPTables check
if ! iptables -t nat -L REDSOCKS >/dev/null 2>&1; then
    echo "  ✅ IPTables rules     - CLEANED"
    PASS=$((PASS+1))
else
    echo "  ❌ IPTables rules     - STILL EXISTS"
    FAIL=$((FAIL+1))
fi

echo "────────────────────────────────────────"
echo "  RESULT: $PASS Passed / $FAIL Failed"
echo "────────────────────────────────────────"

if [ "$FAIL" -eq 0 ]; then
    echo ""
    echo "========================================================"
    echo "    ✅ CLEANUP 100% COMPLETE!                            "
    echo "    BDIX BYPASS v2.0 REMOVED SUCCESSFULLY                "
    echo "    FEEDBACK: @crazy_boy_jahid                           "
    echo "========================================================"
else
    echo ""
    echo "========================================================"
    echo "    ⚠️  SOME FILES COULD NOT BE REMOVED                  "
    echo "    Please reboot router and run again                   "
    echo "    FEEDBACK: @crazy_boy_jahid                           "
    echo "========================================================"
fi
