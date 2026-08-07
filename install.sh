#!/bin/sh

echo "========================================================"
echo "    BDIX BYPASS - AUTO INSTALLER (UNIVERSAL)             "
echo "    Developed by: Jahid Hasan Shuvo (@crazy_boy_jahid)   "
echo "    Version: 2.0 (Multi-Proxy Support)                   "
echo "========================================================"
sleep 2

# [1/4] Package Manager Check and Install
echo -e "\n[1/4] Installing Required Packages..."
if command -v apk >/dev/null 2>&1; then
    apk update
    apk add luci-compat lua liblua5.1.5 luci-lib-base iptables-legacy iptables-mod-nat-extra redsocks
elif command -v opkg >/dev/null 2>&1; then
    opkg update
    opkg install luci-compat lua liblua5.1.5 luci-lib-base iptables-legacy iptables-mod-nat-extra redsocks
else
    echo "Error: No package manager found!"
    exit 1
fi

echo -e "\n[2/4] Configuring Redsocks Backend..."
cat <<'EOF' > /etc/init.d/redsocks
#!/bin/sh /etc/rc.common
START=90
PORT=1337

iptable_start() {
    iptables -t nat -N REDSOCKS 2>/dev/null
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 100.64.0.0/10 -j RETURN
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports ${PORT}
    iptables -t nat -A PREROUTING -p tcp -i br-lan -j REDSOCKS
}

iptable_stop() {
    iptables -t nat -D PREROUTING -p tcp -i br-lan -j REDSOCKS 2>/dev/null
    iptables -t nat -F REDSOCKS 2>/dev/null
    iptables -t nat -X REDSOCKS 2>/dev/null
}

start() {
    if [ -f /var/run/redsocks.pid ]; then
        echo "RedSocks Already Running"
    else
        iptable_start
        /usr/sbin/redsocks -c /etc/redsocks.conf -p /var/run/redsocks.pid
        echo "RedSocks Started"
    fi
}

stop() {
    if [ -f /var/run/redsocks.pid ]; then
        kill $(cat /var/run/redsocks.pid)
        rm -f /var/run/redsocks.pid
        iptable_stop
        echo "RedSocks Stopped"
    else
        iptable_stop
        echo "RedSocks Stopped (force cleanup)"
    fi
}

restart() {
    stop
    sleep 1
    start
}
EOF
chmod +x /etc/init.d/redsocks

cat <<EOF > /etc/redsocks.conf
base { log_debug = off; log_info = off; daemon = on; redirector = iptables; }
redsocks {
    local_ip = 0.0.0.0;
    local_port = 1337;
    ip = 0.0.0.0;
    port = 0;
    type = socks5;
    login = "";
    password = "";
}
EOF

/etc/init.d/redsocks enable

echo -e "\n[3/4] Configuring LuCI UI..."
rm -f /usr/lib/lua/luci/controller/redsocks.lua
rm -f /usr/share/luci/menu.d/luci-app-redsocks.json
rm -rf /usr/lib/lua/luci/view/redsocks/
rm -f /www/cgi-bin/redsocks_ctl

mkdir -p /usr/share/luci/menu.d/
cat << 'EOF' > /usr/share/luci/menu.d/luci-app-redsocks.json
{
    "admin/services": {
        "title": "Services",
        "order": 40
    },
    "admin/services/redsocks": {
        "title": "BDIX_BYPASS",
        "order": 99,
        "action": {
            "type": "template",
            "path": "redsocks/index"
        }
    }
}
EOF

mkdir -p /usr/lib/lua/luci/view/redsocks/
cat << 'EOF' > /usr/lib/lua/luci/view/redsocks/index.htm
<%+header%>
<style>
    :root { --bg: #e2e8f0; --text: #1e293b; --card-bg: #1e293b; --accent: #f59e0b; }
    .dark-mode { --bg: #0f172a; --text: #f1f5f9; --card-bg: #1e293b; }
    body { background-color: var(--bg) !important; color: var(--text) !important; transition: 0.3s; }
    .main-wrapper { display: flex; width: 100%; max-width: 1050px; margin: 40px auto; background: #1e293b; border-radius: 20px; overflow: hidden; box-shadow: 0 20px 50px rgba(0,0,0,0.3); color: #fff; }
    .form-side { width: 38%; padding: 35px; background: #1e293b; border-right: 2px solid #334155; }
    .dash-side { width: 62%; padding: 40px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #263345; }
    .input-field { width: 100%; padding: 12px; border: 1px solid #334155; border-radius: 8px; margin-bottom: 12px; background: #0f172a; color: white; font-size: 14px; }
    .input-field:focus { border-color: #f59e0b; outline: none; }
    .select-field { width: 100%; padding: 12px; border: 1px solid #334155; border-radius: 8px; margin-bottom: 12px; background: #0f172a; color: white; font-size: 14px; cursor: pointer; }
    .select-field:focus { border-color: #f59e0b; outline: none; }
    .btn { padding: 12px; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; color: white; transition: 0.3s; font-size: 13px; }
    .btn:hover { opacity: 0.85; transform: translateY(-1px); }
    .theme-btn { margin-bottom: 15px; padding: 6px 16px; border-radius: 5px; background: transparent; border: 1px solid #475569; color: white; cursor: pointer; font-size: 13px; }
    .slider-img { width: 100%; max-width: 550px; height: 350px; object-fit: cover; border-radius: 10px; border: 2px solid #f59e0b; }
    .section-label { font-size: 11px; text-transform: uppercase; color: #94a3b8; letter-spacing: 1px; margin-bottom: 6px; margin-top: 5px; }
    .auth-toggle { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
    .auth-toggle label { font-size: 13px; color: #94a3b8; }
    .toggle-switch { position: relative; width: 50px; height: 26px; }
    .toggle-switch input { opacity: 0; width: 0; height: 0; }
    .toggle-slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background: #334155; border-radius: 26px; transition: 0.3s; }
    .toggle-slider:before { position: absolute; content: ""; height: 20px; width: 20px; left: 3px; bottom: 3px; background: white; border-radius: 50%; transition: 0.3s; }
    .toggle-switch input:checked + .toggle-slider { background: #f59e0b; }
    .toggle-switch input:checked + .toggle-slider:before { transform: translateX(24px); }
    .auth-fields { transition: 0.3s; overflow: hidden; }
    .status-badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; margin-bottom: 15px; }
    .status-running { background: #0d9488; color: white; }
    .status-stopped { background: #e11d48; color: white; }
    .branding-box { margin-top: 25px; padding: 15px; border-radius: 10px; background: #263345; text-align: center; border-left: 4px solid #f59e0b; }
    .dev-title { font-size: 0.7rem; color: #94a3b8; text-transform: uppercase; letter-spacing: 1px; }
    .dev-name { font-size: 0.9rem; font-weight: bold; margin: 5px 0; }
    .ig-link { font-size: 0.8rem; color: #f59e0b; text-decoration: none; font-weight: bold; }
    .version-tag { font-size: 10px; color: #475569; margin-top: 8px; }
</style>

<div class="main-wrapper">
    <div class="form-side">
        <div style="display:flex; justify-content:space-between; align-items:center;">
            <button class="theme-btn" onclick="toggleTheme()">🌓 Toggle</button>
            <% local pid = luci.util.exec("cat /var/run/redsocks.pid 2>/dev/null") %>
            <% if pid ~= "" then %>
                <span class="status-badge status-running">● RUNNING</span>
            <% else %>
                <span class="status-badge status-stopped">● STOPPED</span>
            <% end %>
        </div>

        <h2 style="margin:10px 0;">⚡ BDIX BYPASS</h2>

        <% local ptype = luci.util.exec("grep -m1 'type =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;'")
           local ip = luci.util.exec("grep -m1 '^[^l]*ip =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;'")
           local port = luci.util.exec("grep -m1 '^[^l]*port =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;'")
           local user = luci.util.exec("grep -m1 'login =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;\"'")
           local pass = luci.util.exec("grep -m1 'password =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;\"'")
           local has_auth = (user ~= "" and user ~= nil) %>

        <form method="post" action="/cgi-bin/redsocks_ctl">
            <div class="section-label">🔌 Proxy Type</div>
            <select name="ptype" class="select-field">
                <option value="socks5" <%if ptype:match("socks5") then%>selected<%end%>>SOCKS5</option>
                <option value="socks4" <%if ptype:match("socks4") then%>selected<%end%>>SOCKS4</option>
                <option value="http-connect" <%if ptype:match("http%-connect") then%>selected<%end%>>HTTP Connect</option>
                <option value="http-relay" <%if ptype:match("http%-relay") then%>selected<%end%>>HTTP Relay</option>
            </select>

            <div class="section-label">🌐 Proxy Server</div>
            <input type="text" name="ip" value="<%=ip%>" class="input-field" placeholder="Proxy IP (e.g. 103.x.x.x)">
            <input type="text" name="port" value="<%=port%>" class="input-field" placeholder="Proxy Port (e.g. 1080)">

            <div class="section-label">🔐 Authentication</div>
            <div class="auth-toggle">
                <label>Auth OFF</label>
                <div class="toggle-switch">
                    <input type="checkbox" id="authToggle" name="auth" value="on" <%if has_auth then%>checked<%end%> onchange="toggleAuth()">
                    <span class="toggle-slider"></span>
                </div>
                <label>Auth ON</label>
            </div>

            <div id="authFields" class="auth-fields">
                <input type="text" name="user" value="<%=user%>" class="input-field" placeholder="Username">
                <input type="password" name="pass" value="<%=pass%>" class="input-field" placeholder="Password">
            </div>

            <div style="display:flex; gap:8px; margin-top:15px;">
                <button type="submit" name="act" value="save" class="btn" style="background:#f59e0b; color:#000; flex:1;">💾 SAVE</button>
                <button type="submit" name="act" value="start" class="btn" style="background:#0d9488; flex:1;">🚀 BOOST</button>
                <button type="submit" name="act" value="stop" class="btn" style="background:#e11d48; flex:1;">🛑 STOP</button>
            </div>
        </form>

        <div class="branding-box">
            <div class="dev-title">❤️ DEVELOPED BY ❤️</div>
            <div class="dev-name">Jahid Hasan Shuvo</div>
            <a href="https://instagram.com/crazy_boy_jahid" target="_blank" class="ig-link">@crazy_boy_jahid</a>
            <div class="version-tag">v2.0 • Multi-Proxy Support</div>
        </div>
    </div>

    <div class="dash-side">
        <img id="slider" src="https://i.postimg.cc/TP7Q9fk7/a-BDi-X-Bypass-Internet-(2).png" class="slider-img">
    </div>
</div>

<script>
    var body = document.body;
    if (localStorage.getItem('theme') === 'dark-mode') {
        body.classList.add('dark-mode');
    }
    function toggleTheme() {
        body.classList.toggle('dark-mode');
        localStorage.setItem('theme', body.classList.contains('dark-mode') ? 'dark-mode' : 'light');
    }

    function toggleAuth() {
        var authFields = document.getElementById('authFields');
        var authToggle = document.getElementById('authToggle');
        if (authToggle.checked) {
            authFields.style.maxHeight = '200px';
            authFields.style.opacity = '1';
        } else {
            authFields.style.maxHeight = '0';
            authFields.style.opacity = '0';
        }
    }
    toggleAuth();

    var images = [
        "https://i.postimg.cc/TP7Q9fk7/a-BDi-X-Bypass-Internet-(2).png",
        "https://i.postimg.cc/Zqstdk65/a-BDi-X-Bypass-Internet-(1).png",
        "https://i.postimg.cc/Zn312C24/a-BDi-X-Bypass-Internet.png"
    ];
    var i = 0;
    setInterval(function(){
        i = (i + 1) % images.length;
        document.getElementById('slider').src = images[i];
    }, 3000);
</script>
<%+footer%>
EOF

cat << 'CGIEOF' > /www/cgi-bin/redsocks_ctl
#!/bin/sh

urldecode() {
    echo "$1" | sed 's/+/ /g;s/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g' | xargs -0 printf "%b" 2>/dev/null
}

read -n "$CONTENT_LENGTH" POST_DATA

ACT=$(echo "$POST_DATA" | grep -o 'act=[^&]*' | cut -d'=' -f2)

if [ "$ACT" = "save" ]; then
    PTYPE=$(echo "$POST_DATA" | grep -o 'ptype=[^&]*' | cut -d'=' -f2)
    IP=$(echo "$POST_DATA" | grep -o 'ip=[^&]*' | cut -d'=' -f2)
    PORT=$(echo "$POST_DATA" | grep -o 'port=[^&]*' | cut -d'=' -f2)
    AUTH=$(echo "$POST_DATA" | grep -o 'auth=[^&]*' | cut -d'=' -f2)
    USER=""
    PASS=""

    if [ "$AUTH" = "on" ]; then
        USER=$(echo "$POST_DATA" | grep -o 'user=[^&]*' | cut -d'=' -f2)
        PASS=$(echo "$POST_DATA" | grep -o 'pass=[^&]*' | cut -d'=' -f2)
        USER=$(urldecode "$USER")
        PASS=$(urldecode "$PASS")
    fi

    IP=$(urldecode "$IP")
    PORT=$(urldecode "$PORT")
    PTYPE=$(urldecode "$PTYPE")

    # Validate IP
    if [ -z "$IP" ] || [ -z "$PORT" ]; then
        echo "Status: 303 See Other"
        echo "Location: /cgi-bin/luci/admin/services/redsocks"
        echo ""
        exit 0
    fi

    # Write config
    cat > /etc/redsocks.conf <<CONFEOF
base { log_debug = off; log_info = off; daemon = on; redirector = iptables; }
redsocks {
    local_ip = 0.0.0.0;
    local_port = 1337;
    ip = ${IP};
    port = ${PORT};
    type = ${PTYPE};
    login = "${USER}";
    password = "${PASS}";
}
CONFEOF

elif [ "$ACT" = "start" ]; then
    /etc/init.d/redsocks stop 2>/dev/null
    sleep 1
    /etc/init.d/redsocks start

elif [ "$ACT" = "stop" ]; then
    /etc/init.d/redsocks stop
fi

echo "Status: 303 See Other"
echo "Location: /cgi-bin/luci/admin/services/redsocks"
echo ""
CGIEOF
chmod +x /www/cgi-bin/redsocks_ctl

echo -e "\n[4/4] Finalizing..."
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/*
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "========================================================================"
echo "    INSTALLED SUCCESSFULLY v2.0                                         "
echo "    New Features:                                                       "
echo "      - Multi Proxy: SOCKS5, SOCKS4, HTTP Connect, HTTP Relay           "
echo "      - Auth ON/OFF Toggle                                              "
echo "      - Live Status Badge (Running/Stopped)                             "
echo "      - URL Decode Security Fix                                         "
echo "      - Improved Error Handling                                         "
echo "    SEND A FEEDBACK TO @crazy_boy_jahid                                 "
echo "========================================================================"
