#!/bin/sh

echo "========================================================"
echo "   BDIX BYPASS - AUTO INSTALLER (BACKEND + FRONTEND)    "
echo "   Developed by: Jahid Hasan Shuvo (@crazy_boy_jahid)   "
echo "========================================================"
sleep 2

echo -e "\n[1/4] Installing Required Packages..."
opkg update
opkg install luci-compat lua liblua5.1.5 luci-lib-base iptables-legacy iptables-mod-nat-extra redsocks

echo -e "\n[2/4] Configuring Redsocks Backend..."
# Creating Service File
cat <<'EOF' > /etc/init.d/redsocks
#!/bin/sh /etc/rc.common
START=90
PORT=1337

iptable_start() {
    iptables -t nat -N REDSOCKS 2>/dev/null
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
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
        echo "RedSocks Are Running Now(PID: $(cat /var/run/redsocks.pid))"
    else
        iptable_start
        /usr/sbin/redsocks -c /etc/redsocks.conf -p /var/run/redsocks.pid
        echo "RedSocks Successfully Started"
    fi
}

stop() {
    if [ -f /var/run/redsocks.pid ]; then
        kill $(cat /var/run/redsocks.pid)
        rm -f /var/run/redsocks.pid
        iptable_stop
        echo "RedSocks Successfully Stopped"
    else
        echo "RedSocks Not Running Now"
    fi
}
EOF
chmod +x /etc/init.d/redsocks

# Config file creating
cat <<EOF > /etc/redsocks.conf
base { log_debug = off; log_info = off; daemon = on; redirector = iptables; }
redsocks {
    local_ip = 0.0.0.0;
    local_port = 1337;
    ip = Type_your_Proxy;
    port = Type_your_Port;
    type = socks5;
    login = "Type_your_username";
    password = "Type_your_password";
}
EOF

# service enable and start
/etc/init.d/redsocks enable
/etc/init.d/redsocks start


echo -e "\n[3/4] Configuring LuCI UI (Frontend)..."
# Cleaning old file
rm -f /usr/lib/lua/luci/controller/redsocks.lua
rm -f /usr/share/luci/menu.d/luci-app-redsocks.json
rm -rf /usr/lib/lua/luci/view/redsocks/
rm -f /www/cgi-bin/redsocks_ctl

# JSON Menu File create
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

# UI File create
mkdir -p /usr/lib/lua/luci/view/redsocks/
cat << 'EOF' > /usr/lib/lua/luci/view/redsocks/index.htm
<%+header%>
<style>
    :root { --bg: #e2e8f0; --text: #1e293b; --card-bg: #1e293b; --accent: #f59e0b; }
    .dark-mode { --bg: #0f172a; --text: #f1f5f9; --card-bg: #1e293b; }
    
    body { background-color: var(--bg) !important; color: var(--text) !important; transition: 0.3s; }
    .main-wrapper { display: flex; width: 100%; max-width: 1000px; margin: 40px auto; background: #1e293b; border-radius: 20px; overflow: hidden; box-shadow: 0 20px 50px rgba(0,0,0,0.3); color: #fff; }
    .form-side { width: 35%; padding: 40px; background: #1e293b; border-right: 2px solid #334155; }
    .dash-side { width: 65%; padding: 40px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #263345; }
    
    .input-field { width: 100%; padding: 12px; border: 1px solid #334155; border-radius: 8px; margin-bottom: 15px; background: #1e293b; color: white; }
    .btn { padding: 12px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold; color: white; transition: 0.3s; }
    .theme-btn { margin-bottom: 20px; padding: 5px 15px; border-radius: 5px; background: transparent; border: 1px solid #475569; color: white; cursor: pointer; font-size: 0.8rem; }
    
    .branding-card { margin-top: 30px; padding: 18px; border-radius: 12px; background: rgba(0,0,0,0.2); border-left: 5px solid #f59e0b; text-align: center; }
    .dev-title { color: #f59e0b; font-size: 0.65rem; letter-spacing: 2px; text-transform: uppercase; font-weight: bold; }
    .dev-name { font-size: 1.05rem; font-weight: bold; color: #fff; margin: 6px 0; }
    .ig-link { display: inline-block; padding: 6px 16px; background: #f59e0b; color: #000; border-radius: 20px; text-decoration: none; font-weight: bold; font-size: 0.75rem; margin-top: 8px; transition: 0.3s; }
    .ig-link:hover { transform: scale(1.05); background: #fbbf24; }
    
    .slider-img { width: 100%; max-width: 550px; height: 350px; object-fit: cover; border-radius: 10px; border: 2px solid #f59e0b; }
</style>

<div class="main-wrapper">
    <div class="form-side">
        <button class="theme-btn" onclick="toggleTheme()">🌓 Toggle Mode</button>
        <h2>BDIX_BYPASS</h2>
        <% local ip = luci.util.exec("grep -m1 '^[^l]*ip =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;'")
           local port = luci.util.exec("grep -m1 '^[^l]*port =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;'")
           local user = luci.util.exec("grep -m1 '^login =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;\"'")
           local pass = luci.util.exec("grep -m1 '^password =' /etc/redsocks.conf | cut -d'=' -f2 | tr -d ' ;\"'") %>
        <form method="post" action="/cgi-bin/redsocks_ctl">
            <div style="font-size:0.8rem; margin-bottom:5px;">Proxy IP</div>
            <input type="text" name="ip" value="<%=ip%>" class="input-field">
            <div style="font-size:0.8rem; margin-bottom:5px;">Proxy Port</div>
            <input type="text" name="port" value="<%=port%>" class="input-field">
            <div style="font-size:0.8rem; margin-bottom:5px;">Username</div>
            <input type="text" name="user" value="<%=user%>" class="input-field">
            <div style="font-size:0.8rem; margin-bottom:5px;">Password</div>
            <input type="password" name="pass" value="<%=pass%>" class="input-field">
            <div style="display:flex; gap:10px; margin-top:10px;">
                <button type="submit" name="act" value="save" class="btn" style="background:#ffffff; color:#000; flex:1;">SAVE</button>
                <button type="submit" name="act" value="start" class="btn" style="background:#0d9488; flex:1;">BOOST</button>
                <button type="submit" name="act" value="stop" class="btn" style="background:#e11d48; flex:1;">STOP</button>
            </div>
        </form>
        
        <div class="branding-card">
            <div class="dev-title">DEVELOPED BY</div>
            <div class="dev-name">JAHID HASAN SHUVO</div>
            <a href="https://instagram.com/crazy_boy_jahid" target="_blank" class="ig-link">@crazy_boy_jahid</a>
        </div>
    </div>
    <div class="dash-side">
        <img id="slider" src="https://i.postimg.cc/TP7Q9fk7/a-BDi-X-Bypass-Internet-(2).png" class="slider-img">
        <h3 style="color: #f59e0b; margin-top: 25px;">ROCKET SPEED ENABLED</h3>
    </div>
</div>

<script>
    function applyTheme() {
        if (localStorage.getItem('theme') === 'light') {
            document.body.classList.remove('dark-mode');
        } else {
            document.body.classList.add('dark-mode');
        }
    }
    function toggleTheme() {
        document.body.classList.toggle('dark-mode');
        localStorage.setItem('theme', document.body.classList.contains('dark-mode') ? 'dark' : 'light');
    }
    applyTheme();

    var images = [
        "https://i.postimg.cc/TP7Q9fk7/a-BDi-X-Bypass-Internet-(2).png",
        "https://i.postimg.cc/Zqstdk65/a-BDi-X-Bypass-Internet-(1).png",
        "https://i.postimg.cc/Zn312C24/a-BDi-X-Bypass-Internet.png"
    ];
    var i = 0;
    setInterval(function(){ i = (i + 1) % images.length; document.getElementById('slider').src = images[i]; }, 3000);
</script>
<%+footer%>
EOF

# Backend controller create 
cat << 'EOF' > /www/cgi-bin/redsocks_ctl
#!/bin/sh
read -n "$CONTENT_LENGTH" POST_DATA
ACT=$(echo "$POST_DATA" | grep -o 'act=[^&]*' | cut -d'=' -f2)
if [ "$ACT" = "save" ]; then
    IP=$(echo "$POST_DATA" | grep -o 'ip=[^&]*' | cut -d'=' -f2); PORT=$(echo "$POST_DATA" | grep -o 'port=[^&]*' | cut -d'=' -f2)
    USER=$(echo "$POST_DATA" | grep -o 'user=[^&]*' | cut -d'=' -f2); PASS=$(echo "$POST_DATA" | grep -o 'pass=[^&]*' | cut -d'=' -f2)
    sed -i "/^[^l]*ip =/s/ip = .*/ip = $IP;/" /etc/redsocks.conf
    sed -i "/^[^l]*port =/s/port = .*/port = $PORT;/" /etc/redsocks.conf
    sed -i "s/login = .*/login = \"$USER\";/" /etc/redsocks.conf
    sed -i "s/password = .*/password = \"$PASS\";/" /etc/redsocks.conf
elif [ "$ACT" = "start" ]; then /etc/init.d/redsocks stop; sleep 1; /etc/init.d/redsocks start
elif [ "$ACT" = "stop" ]; then /etc/init.d/redsocks stop
fi
echo "Status: 303 See Other"; echo "Location: /cgi-bin/luci/admin/services/redsocks"; echo ""
EOF
chmod +x /www/cgi-bin/redsocks_ctl

echo -e "\n[4/4] Clearing Cache and Restarting Services..."
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/*
/etc/init.d/rpcd restart
/etc/init.d/uhttpd restart

echo "========================================================"
echo "    ALL DONE! Backend and UI successfully installed.    "
echo "    Please refresh your OpenWrt LuCI browser panel.     "
echo "========================================================"