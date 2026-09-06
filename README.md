# kreo-mouse-fix-linux

Makes the 2 custom-assignable buttons on a Kreo Chimera mouse (the "3+2"
button gaming mice) work on Linux, where they normally do nothing.

## Why they don't work

The mouse's HID report descriptor reserves 5 bits in its button byte but
only assigns HID usages to the first 3 (Left/Right/Middle). The 2 custom
buttons *do* set bits 3 and 4 (`0x08` and `0x10`) in that byte, but since
the descriptor never declares a usage for them, per spec they're
undefined.

Windows' own inbox HID mouse driver natively understands 5 buttons
(left, right, middle, plus button 4 and 5 as back/forward), no vendor
driver involved. That's why back/forward already works on Windows
before installing anything from Kreo. The exact mechanism behind its
tolerance for this descriptor's usage mismatch isn't publicly
documented. Linux's `hid-generic` driver is stricter. It only creates
input events for usages actually declared in range, so bits 3 and 4
get dropped.

This tool reads the raw `hidraw` reports directly (bypassing the normal
HID-input layer) and emits real button events through a virtual
`uinput` device instead.

By default the 2 buttons are mapped to `BTN_SIDE`/`BTN_EXTRA` (mouse
back/forward), which browsers and file managers already understand out
of the box.

## Requirements

- Linux with `/dev/uinput` available (standard on any modern kernel)
- Python 3 with the `evdev` module (`python-evdev` / `python3-evdev`)
- A Kreo Chimera mouse (or any device reporting vendor:product `248A:8266`)

## Install

```sh
sudo ./install.sh
```

This installs the daemon to `/usr/bin/kreo-extra-buttons`, installs a
systemd unit, and starts it immediately (and on every future boot). It
auto-detects the mouse's `hidraw` device by vendor/product ID, so it
survives reboots, reconnects, and differing `hidraw` numbering across
machines.

Check it's running:

```sh
systemctl status kreo-extra-buttons
journalctl -u kreo-extra-buttons -f   # connection status (found/lost the mouse, etc.)
```

To also log every button press/release (useful when debugging a remap),
set `KREO_DEBUG=1` in the systemd unit's `[Service]` section (add
`Environment=KREO_DEBUG=1`) and restart the service.

## Uninstall

```sh
sudo ./uninstall.sh
```

## Remapping the buttons

Edit `/etc/kreo-extra-buttons.conf`:

```
button1=BTN_SIDE
button2=BTN_EXTRA
```

`button1` is the custom button that sends bit `0x08`, `button2` is the
one that sends `0x10` (see [Adapting for other Kreo mice](#adapting-for-other-kreo-mice)
if you're not sure which is which). Either can be set to any evdev
`BTN_*` or `KEY_*` code. See the full list with:

```sh
python3 -c "from evdev import ecodes; print('\n'.join(sorted(n for n in ecodes.ecodes if n.startswith(('BTN_','KEY_')))))"
```

Then apply the change:

```sh
sudo systemctl restart kreo-extra-buttons
```

Reassigning the buttons in the Windows Chimera app has no effect on
Linux. That reassignment only changes what the Windows software does
when it sees the raw button signal, it doesn't reprogram the mouse
itself. The `.conf` file above is the Linux-side equivalent.

## Adapting for other Kreo mice

If your mouse has a different vendor/product ID, or a different bit
layout for its extra buttons, find it with:

```sh
cat /sys/class/hidraw/hidraw*/device/uevent   # find HID_ID and HID_NAME
sudo xxd /dev/hidrawN                         # press buttons, watch which byte/bit changes
```

Update `VENDOR_ID` and `PRODUCT_ID` at the top of
`/usr/bin/kreo-extra-buttons` to match, and `BUTTON_SLOTS` if the extra
buttons use different bits than `0x08`/`0x10`. What each button does is
still set through `/etc/kreo-extra-buttons.conf`, as above.
