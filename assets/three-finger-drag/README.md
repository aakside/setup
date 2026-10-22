# Magic Trackpad 2 three-finger drag

Enables libinput's built-in three-finger drag on Apple Magic Trackpad 2
(vendor `05ac` or `004c`, product `0265`) in Ubuntu GNOME Wayland.
Requires libinput **1.28 or newer**, GCC, Python 3 and matching libinput
development headers. Verified on Ubuntu 26.04.1, GNOME 50.1 and libinput 1.31.1.
Ubuntu 24.04's stock libinput is too old; this does not install an old fork.

From the repository root:

```sh
sudo apt install build-essential pkg-config libinput-dev
scripts/three-finger-drag.sh install
```

Run the installer as your normal user, without sudo. It builds and tests the
helper, then installs these user files:

- `~/.local/lib/apple-three-finger-drag/libapple-three-finger-drag.so`
- `${XDG_CONFIG_HOME:-~/.config}/systemd/user/org.gnome.Shell@ubuntu.service.d/60-apple-three-finger-drag.conf`

Save work and log out/in to activate. The setup script calls this command only
in a supported active Ubuntu GNOME Wayland session. Running it again updates
the installed helper. No running desktop is restarted.

## How it works

The service drop-in uses `LD_PRELOAD` to load the helper in GNOME. It intercepts
`libinput_get_event`, checks device-added events and calls
`libinput_device_config_3fg_drag_set_enabled` for matching, capable devices.
Events pass through unchanged. Libinput implements the gesture; this helper
does not record input or emulate mouse events. Reconnecting the device enables
it again. Other devices are untouched.

No system library, quirks file, GNOME preference, or global preload setting is
changed. Compatible automatic libinput upgrades normally need no rebuild or
reinstallation. Future GNOME service changes may require adjustment; remove
this workaround when GNOME provides a native setting. Direct children of
GNOME may inherit the preload, but it only acts on matching libinput devices.
As with any compositor-loaded code, a bug could affect desktop stability.

## Behavior and verification

Three fingers initiate dragging without a click. Leaving two fingers down
continues the drag; leaving one ends it. Briefly lifting and replacing three
fingers can continue the drag. Timing and acceleration follow libinput, not
an exact macOS clone. Libinput 1.31 also recognizes fast three-finger swipes,
which may activate GNOME gestures. Tap-to-click retains its existing setting.

```sh
scripts/three-finger-drag.sh status
journalctl --user -b -u org.gnome.Shell@ubuntu.service --no-pager | grep apple-three-finger-drag
```

After login, expect `status=0 enabled=1` for each usable trackpad interface.
Test text selection, window dragging/resizing, lift-and-resume, tapping,
scrolling, gestures and unplug/reconnect. A configured service is not proof
that the running session has loaded the helper.

## Disable

```sh
scripts/three-finger-drag.sh disable
```

Then log out/in. This removes only the helper's own drop-in and reloads systemd;
the installed library remains inert on disk. Install enables it again. If the
desktop cannot start, use Ctrl+Alt+F3, log in and run the disable command.
No files in this repository or in Documents are needed at runtime.

## Development

```sh
scripts/three-finger-drag.sh build
scripts/three-finger-drag.sh test
```

Build products and checksums stay in the ignored `build/` directory. Tests cover
USB/Bluetooth matching, unrelated devices, insufficient finger support,
motion/removal passthrough, API failure, reconnection and an empty queue.
The installer refuses conflicting preload settings and edited drop-ins.

To use extracted development headers, download the package matching the host
with `apt-get download libinput-dev`, extract it with `dpkg-deb -x`, then run:

```sh
LIBINPUT_INCLUDE_DIR=/absolute/path/to/extracted/usr/include scripts/three-finger-drag.sh test
```

The same override works with `install`. The probe can check explicit trackpad
event nodes in a separate, short-lived context; it neither grabs the device
nor waits for input. Discover the current nodes in `/proc/bus/input/devices`:

```sh
sudo env LD_PRELOAD="$PWD/assets/three-finger-drag/build/libapple-three-finger-drag.so" \
  assets/three-finger-drag/build/probe /dev/input/eventN
```

The original hardware check on both USB interfaces returned 16 supported
fingers and `enabled=1`. That confirms API support, not compositor activation.

## References

- [Merged upstream implementation](https://gitlab.freedesktop.org/libinput/libinput/-/merge_requests/1042)
- [Current behavior in libinput 1.31](https://wayland.freedesktop.org/libinput/doc/1.31.0/drag-3fg.html)
- [Original feature request](https://gitlab.freedesktop.org/libinput/libinput/-/work_items/298)
- Earlier alternatives reviewed: [abcdef](https://gitlab.freedesktop.org/abcdef/libinput/-/commits/resumable-3fd), [aakside](https://github.com/aakside/libinput), [complyue](https://github.com/complyue/libinput).
- [Related preload approach](https://github.com/joaodriessen/enable-3fg-drag); its global installer is not used here.
