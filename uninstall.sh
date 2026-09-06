#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./uninstall.sh" >&2
  exit 1
fi

systemctl disable --now kreo-extra-buttons.service 2>/dev/null || true
rm -f /etc/systemd/system/kreo-extra-buttons.service
rm -f /usr/bin/kreo-extra-buttons
systemctl daemon-reload

echo "Uninstalled."
