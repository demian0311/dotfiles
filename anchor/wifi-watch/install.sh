#!/bin/bash
# Install the anchor Wi-Fi link watcher. Run once, as root, on anchor:
#     ssh anchor -t 'sudo bash ~/code/dotfiles/anchor/wifi-watch/install.sh'
# Uninstall with:
#     ssh anchor -t 'sudo bash ~/code/dotfiles/anchor/wifi-watch/install.sh --uninstall'
set -euo pipefail
(( EUID == 0 )) || { echo "run with sudo" >&2; exit 1; }

if [[ ${1:-} == --uninstall ]]; then
  systemctl disable --now wifi-watch.timer 2>/dev/null || true
  rm -f /etc/systemd/system/wifi-watch.{service,timer} /usr/local/bin/wifi-watch /etc/logrotate.d/wifi-watch
  systemctl daemon-reload
  echo "removed. History kept at /var/log/wifi-watch.log and state at /var/lib/wifi-watch."
  exit 0
fi

install -m 0755 -o root -g root "$(dirname "$(readlink -f "$0")")/wifi-watch" /usr/local/bin/wifi-watch
install -d -m 0755 /var/lib/wifi-watch
touch /var/log/wifi-watch.log; chmod 0644 /var/log/wifi-watch.log

cat >/etc/systemd/system/wifi-watch.service <<'EOF'
[Unit]
Description=Check anchor's Wi-Fi link and re-associate it if the wl driver has collapsed
After=NetworkManager.service
Wants=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wifi-watch
# The bounce takes ~90s worst case; never let a hung run block the next one forever.
TimeoutStartSec=300
EOF

cat >/etc/systemd/system/wifi-watch.timer <<'EOF'
[Unit]
Description=Check anchor's Wi-Fi link every 5 minutes

[Timer]
# Late enough after boot that NetworkManager has associated once.
OnBootSec=3min
OnUnitActiveSec=5min
AccuracySec=30s

[Install]
WantedBy=timers.target
EOF

cat >/etc/logrotate.d/wifi-watch <<'EOF'
/var/log/wifi-watch.log {
  weekly
  rotate 8
  compress
  missingok
  notifempty
  copytruncate
}
EOF

systemctl daemon-reload
systemctl enable --now wifi-watch.timer

echo
echo "=== installed ==="
systemctl is-enabled wifi-watch.timer | sed 's/^/  timer enabled: /'
systemctl is-active  wifi-watch.timer | sed 's/^/  timer active:  /'
echo "  next run:"; systemctl list-timers wifi-watch.timer --no-pager | sed -n '2p' | sed 's/^/    /'
echo
echo "=== running one check now to prove it works ==="
systemctl start wifi-watch.service
sleep 12
echo "  last log lines:"; tail -3 /var/log/wifi-watch.log | sed 's/^/    /'
echo
echo "History:  /var/log/wifi-watch.log"
echo "State:    /var/lib/wifi-watch/  (strikes, bounces, cooldown_until)"
