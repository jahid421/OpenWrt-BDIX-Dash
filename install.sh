#!/bin/sh

echo "========================================================"
echo "    BDIX BYPASS - AUTO INSTALLER (UNIVERSAL)             "
echo "    Developed by: Jahid Hasan Shuvo (@crazy_boy_jahid)   "
echo "    Version: 2.1 (Multi-Proxy + HTTP Fix)                "
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

iptable_start() {
    iptables -t nat -N REDSOCKS 2>/dev/null
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 100.64.0.0/10 -j RETURN
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 1337
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
    .input-field { width: 100%; padding: 12px; border: 1px solid #334155; border-radius: 8px; margin-bottom: 12px; background: #0f172a; color: #f1f5f9; font-size: 14px; box-sizing: border-box; }
    .input-field:focus { border-color: #f59e0b; outline: none; }
    .input-field:disabled { opacity: 0.4; cursor: not-allowed; }

    /* FIXED: Proxy Type Selector - Visible Selected Value */
    .proxy-select-box { position: relative; margin-bottom: 12px; }
    .proxy-select { width: 100%; padding: 14px 45px 14px 14px; border: 2px solid #334155; border-radius: 10px; background: #0f172a; color: #f59e0b; font-size: 15px; font-weight: bold; cursor: pointer; -webkit-appearance: none; -moz-appearance: none; appearance: none; box-sizing: border-box; }
    .proxy-select:focus { border-color: #f59e0b; outline: none; box-shadow: 0 0 10px rgba(245,158,11,0.3); }
    .proxy-select option { background: #0f172a; color: #f1f5f9; padding: 12px; font-size: 14px; font-weight: normal; }
    .proxy-select option:checked { background: #1e3a5f; color: #f59e0b; }
    .proxy-arrow { position: absolute; right: 14px; top: 50%; transform: translateY(-50%); color: #f59e0b; font-size: 14px; pointer-events: none; }
    .proxy-selected-label { margin-top: 6px; padding: 6px 12px; background: #162032; border-radius: 6px; font-size: 12px; color: #f59e0b; display: inline-block; border: 1px solid #f59e0b33; }

    .btn { padding: 12px; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; color: white; transition: 0.3s; font-size: 13px; box-sizing: border-box; }
    .btn:hover { opacity: 0.85; transform: translateY(-1px); }
    .theme-btn { margin-bottom: 15px; padding: 6px 16px; border-radius: 5px; background: transparent; border: 1px solid #475569; color: white; cursor: pointer; font-size: 13px; }
    .slider-img { width: 100%; max-width: 550px; height: 350px; object-fit: cover; border-radius: 10px; border: 2px solid #f59e0b; }
    .section-label { font-size: 11px; text-transform: uppercase; color: #94a3b8; letter-spacing: 1px; margin-bottom: 6px; margin-top: 5px; }
    .auth-box { margin-bottom: 12px; }
    .auth-header { display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; background: #162032; border-radius: 8px; cursor: pointer; border: 1px solid #334155; transition: 0.3s; }
    .auth-header:hover { border-color: #f59e0b; }
    .auth-label { font-size: 13px; color: #94a3b8; }
    .auth-status { font-size: 12px; font-weight: bold; padding: 3px 10px; border-radius: 12px; }
    .auth-on { background: #0d9488; color: white; }
    .auth-off { background: #475569; color: #94a3b8; }
    .auth-fields { max-height: 0; opacity: 0; overflow: hidden; transition: all 0.3s ease; padding: 0 5px; }
    .auth-fields.show { max-height: 200px; opacity: 1; padding-top: 12px; }
    .proxy-info { font-size: 11px; color: #94a3b8; margin-top: 6px; margin-bottom: 12px; padding: 10px; background: #162032; border-radius: 8px; border-left: 3px solid #f59e0b; line-height: 1.6; }
    .status-badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; }
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
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px;">
            <button class="theme-btn" onclick="toggleTheme()">🌓 Toggle</button>
            <% local pid = luci.util.exec("cat /var/run/redsocks.pid 2>/dev/null"):gsub("%s+", "") %>
            <% if pid ~= "" then %>
                <span class="status-badge status-running">● RUNNING</span>
            <% else %>
                <span class="status-badge status-stopped">● STOPPED</span>
            <% end %>
        </div>

        <h2 style="margin:10px 0;">⚡ BDIX BYPASS</h2>

        <%
           local conf = luci.util.exec("cat /etc/redsocks.conf 2>/dev/null") or ""
           local ptype = conf:match("type%s*=%s*([^;]+)") or "socks5"
           ptype = ptype:gsub("%s+", "")
           local user = conf:match('login%s*=%s*"([^"]*)"') or ""
           local pass = conf:match('password%s*=%s*"([^"]*)"') or ""
           local ip = ""
           local port = ""
           for line in conf:gmatch("[^\n]+") do
               if line:match("^%s*ip%s*=") and not line:match("local_ip") then
                   ip = line:match("=%s*([^;]+)") or ""
                   ip = ip:gsub("%s+", "")
               end
               if line:match("^%s*port%s*=") and not line:match("local_port") then
                   port = line:match("=%s*([^;]+)") or ""
                   port = port:gsub("%s+", "")
               end
           end
           if ptype == "http-connect" or ptype == "http-relay" then ptype = "http" end
           local has_auth = (user ~= "" and user ~= nil)
        %>

        <form method="post" action="/cgi-bin/redsocks_ctl">
            <div class="section-label">🔌 Proxy Type</div>
            <div class="proxy-select-box">
                <select name="ptype" id="proxyType" class="proxy-select" onchange="showProxyInfo()">
                    <option value="socks5" <%if ptype == "socks5" then%>selected<%end%>>🧦 SOCKS5</option>
                    <option value="socks4" <%if ptype == "socks4" then%>selected<%end%>>🧦 SOCKS4</option>
                    <option value="http" <%if ptype == "http" then%>selected<%end%>>🌐 HTTP / HTTPS</option>
                </select>
                <span class="proxy-arrow">▼</span>
            </div>
            <div id="currentType" class="proxy-selected-label"></div>
            <div id="proxyInfo" class="proxy-info" style="display:none;"></div>

            <div class="section-label">🌐 Proxy Server</div>
            <input type="text" name="ip" value="<%=ip%>" class="input-field" placeholder="Proxy IP (e.g. 103.x.x.x)">
            <input type="text" name="port" value="<%=port%>" class="input-field" placeholder="Proxy Port (e.g. 1080)">

            <div class="section-label">🔐 Authentication</div>
            <div class="auth-box">
                <div class="auth-header" onclick="toggleAuth()" id="authHeader">
                    <span class="auth-label">🔐 Username & Password</span>
                    <span class="auth-status auth-off" id="authBadge">DISABLED</span>
                </div>
                <input type="hidden" name="auth" id="authValue" value="<%if has_auth then%>on<%else%>off<%end%>">
                <div id="authFields" class="auth-fields">
                    <input type="text" name="user" id="userField" value="<%=user%>" class="input-field" placeholder="Username" <%if not has_auth then%>disabled<%end%>>
                    <input type="password" name="pass" id="passField" value="<%=pass%>" class="input-field" placeholder="Password" <%if not has_auth then%>disabled<%end%>>
                </div>
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
            <div class="version-tag">v2.1 • Multi-Proxy + HTTP Fix</div>
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

    var authEnabled = document.getElementById('authValue').value === 'on';

    function toggleAuth() {
        var fields = document.getElementById('authFields');
        var badge = document.getElementById('authBadge');
        var authVal = document.getElementById('authValue');
        var userField = document.getElementById('userField');
        var passField = document.getElementById('passField');
        var header = document.getElementById('authHeader');

        authEnabled = !authEnabled;

        if (authEnabled) {
            fields.className = 'auth-fields show';
            badge.className = 'auth-status auth-on';
            badge.textContent = 'ENABLED';
            authVal.value = 'on';
            userField.disabled = false;
            passField.disabled = false;
            header.style.borderColor = '#0d9488';
        } else {
            fields.className = 'auth-fields';
            badge.className = 'auth-status auth-off';
            badge.textContent = 'DISABLED';
            authVal.value = 'off';
            userField.disabled = true;
            passField.disabled = true;
            userField.value = '';
            passField.value = '';
            header.style.borderColor = '#334155';
        }
    }

    function initAuth() {
        var fields = document.getElementById('authFields');
        var badge = document.getElementById('authBadge');
        var header = document.getElementById('authHeader');

        if (authEnabled) {
            fields.className = 'auth-fields show';
            badge.className = 'auth-status auth-on';
            badge.textContent = 'ENABLED';
            header.style.borderColor = '#0d9488';
        } else {
            fields.className = 'auth-fields';
            badge.className = 'auth-status auth-off';
            badge.textContent = 'DISABLED';
            header.style.borderColor = '#334155';
        }
    }
    initAuth();

    var proxyNames = {
        'socks5': '🧦 SOCKS5 Selected',
        'socks4': '🧦 SOCKS4 Selected',
        'http': '🌐 HTTP/HTTPS Selected'
    };

    var proxyInfoData = {
        'socks5': '✅ SOCKS5 proxy ব্যবহার করুন।<br>📌 সবচেয়ে জনপ্রিয় এবং নির্ভরযোগ্য।<br>📌 BDIX bypass এর জন্য সেরা।<br>📌 Authentication সাপোর্ট করে।',
        'socks4': '✅ SOCKS4 proxy ব্যবহার করুন।<br>📌 Lightweight এবং দ্রুত।<br>📌 বাংলাদেশের ISP গুলোর সাথে ভালো কাজ করে।<br>📌 Authentication সাপোর্ট করে।',
        'http': '✅ HTTP proxy ব্যবহার করুন।<br>📌 HTTP + HTTPS দুইটাই চলবে।<br>📌 Port 80 (HTTP) ও Port 443 (HTTPS) অটো হ্যান্ডেল হবে।<br>📌 Authentication সাপোর্ট করে।'
    };

    function showProxyInfo() {
        var select = document.getElementById('proxyType');
        var info = document.getElementById('proxyInfo');
        var label = document.getElementById('currentType');
        var val = select.value;

        if (proxyNames[val]) {
            label.textContent = proxyNames[val];
            label.style.display = 'inline-block';
        }

        if (proxyInfoData[val]) {
            info.innerHTML = proxyInfoData[val];
            info.style.display = 'block';
        } else {
            info.style.display = 'none';
        }
    }
    showProxyInfo();

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
    local data="$1"
    data=$(echo "$data" | sed 's/+/ /g')
    printf '%b' "$(echo "$data" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g')"
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

    IP=$(urldecode "$IP")
    PORT=$(urldecode "$PORT")
    PTYPE=$(urldecode "$PTYPE")

    if [ "$AUTH" = "on" ]; then
        USER=$(echo "$POST_DATA" | grep -o 'user=[^&]*' | cut -d'=' -f2)
        PASS=$(echo "$POST_DATA" | grep -o 'pass=[^&]*' | cut -d'=' -f2)
        USER=$(urldecode "$USER")
        PASS=$(urldecode "$PASS")
    fi

    if [ -z "$IP" ] || [ -z "$PORT" ]; then
        echo "Status: 303 See Other"
        echo "Location: /cgi-bin/luci/admin/services/redsocks"
        echo ""
        exit 0
    fi

    LOGIN_LINE="login = \"${USER}\";"
    PASS_LINE="password = \"${PASS}\";"

    if [ "$PTYPE" = "http" ]; then
        cat > /etc/redsocks.conf <<CONFEOF
base { log_debug = off; log_info = off; daemon = on; redirector = iptables; }
redsocks {
    local_ip = 0.0.0.0;
    local_port = 1337;
    ip = ${IP};
    port = ${PORT};
    type = http-connect;
    ${LOGIN_LINE}
    ${PASS_LINE}
}
redsocks {
    local_ip = 0.0.0.0;
    local_port = 1338;
    ip = ${IP};
    port = ${PORT};
    type = http-relay;
    ${LOGIN_LINE}
    ${PASS_LINE}
}
CONFEOF

        # Update iptables for dual port
        cat > /etc/init.d/redsocks <<'INITEOF'
#!/bin/sh /etc/rc.common
START=90

iptable_start() {
    iptables -t nat -N REDSOCKS 2>/dev/null
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 100.64.0.0/10 -j RETURN
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A REDSOCKS -p tcp --dport 443 -j REDIRECT --to-ports 1337
    iptables -t nat -A REDSOCKS -p tcp --dport 80 -j REDIRECT --to-ports 1338
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 1337
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
        echo "RedSocks Started (HTTP/HTTPS Mode)"
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
INITEOF
        chmod +x /etc/init.d/redsocks

    else
        cat > /etc/redsocks.conf <<CONFEOF
base { log_debug = off; log_info = off; daemon = on; redirector = iptables; }
redsocks {
    local_ip = 0.0.0.0;
    local_port = 1337;
    ip = ${IP};
    port = ${PORT};
    type = ${PTYPE};
    ${LOGIN_LINE}
    ${PASS_LINE}
}
CONFEOF

        cat > /etc/init.d/redsocks <<'INITEOF'
#!/bin/sh /etc/rc.common
START=90

iptable_start() {
    iptables -t nat -N REDSOCKS 2>/dev/null
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 100.64.0.0/10 -j RETURN
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 1337
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
INITEOF
        chmod +x /etc/init.d/redsocks
    fi

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
echo "    INSTALLED SUCCESSFULLY v2.1                                         "
echo "    New Features:                                                       "
echo "      - Multi Proxy: SOCKS5, SOCKS4, HTTP/HTTPS                        "
echo "      - HTTP Proxy: HTTP + HTTPS Both Supported                        "
echo "      - Visible Proxy Type Selection with Label                        "
echo "      - Auth Enable/Disable (All Proxy Types)                          "
echo "      - Proxy Type Info Helper (Bangla)                                "
echo "      - Live Status Badge (Running/Stopped)                            "
echo "      - URL Decode Security Fix                                        "
echo "    SEND A FEEDBACK TO @crazy_boy_jahid                                "
echo "========================================================================"
