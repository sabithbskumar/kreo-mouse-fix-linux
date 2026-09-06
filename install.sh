#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./install.sh" >&2
  exit 1
fi

if ! python3 -c "import evdev" 2>/dev/null; then
  cat >&2 <<'EOF'
python-evdev is required but not found. Install it first:
  Arch:          sudo pacman -S python-evdev
  Debian/Ubuntu: sudo apt install python3-evdev
  Fedora:        sudo dnf install python3-evdev
  Any (pip):     sudo pip install evdev
EOF
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -Dm755 "$script_dir/bin/kreo-extra-buttons" \
  /usr/bin/kreo-extra-buttons
install -Dm644 "$script_dir/systemd/kreo-extra-buttons.service" \
  /etc/systemd/system/kreo-extra-buttons.service

if [[ ! -f /etc/kreo-extra-buttons.conf ]]; then
  install -Dm644 "$script_dir/kreo-extra-buttons.conf" \
    /etc/kreo-extra-buttons.conf
else
  echo "Keeping existing /etc/kreo-extra-buttons.conf"
fi

systemctl daemon-reload
systemctl enable --now kreo-extra-buttons.service
systemctl restart kreo-extra-buttons.service

echo "Installed and started."
echo "Check status with: systemctl status kreo-extra-buttons"
echo "Watch its log with: journalctl -u kreo-extra-buttons -f"
