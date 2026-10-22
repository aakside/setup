# Setup

This is to help [me](https://github.com/aakside) get a new personal computer up and running.

Run scripts/configure.sh

## Apple Magic Trackpad 2 (Ubuntu GNOME Wayland)

Setup enables native three-finger drag when libinput >=1.28 and the active
Ubuntu GNOME Wayland session support it. It can also be managed independently:

```sh
scripts/three-finger-drag.sh install
scripts/three-finger-drag.sh status
scripts/three-finger-drag.sh disable
```

Log out/in after installing or disabling. See
[the helper documentation](assets/three-finger-drag/README.md) for dependencies,
behavior, tests and rollback. System libinput packages are not replaced.

## Magic Trackpad moves only when pressed or moved very fast

An old manual libinput installation can leave incompatible `.quirks` files in
`/usr/share/libinput`. A parser error disables the entire quirks database,
including Apple's touch-detection settings. This was the cause on my workstation;
other causes can produce similar symptoms.

**This repair is opt-in and is never run by `scripts/configure.sh`.** From the
repository root, start with the read-only check (no sudo needed):

```sh
python3 scripts/trackpad-quirks.py check
```

- Exit 0: the database is valid; this fix is not needed.
- Exit 1: the known defect is present and the proposed repair passes validation.
- Exit 2: the problem is different, the files have changed, or a check failed;
  read the diagnostic and investigate instead of forcing the repair.

If the check reports that the known repair is applicable, explicitly run:

```sh
sudo python3 scripts/trackpad-quirks.py apply
```

The command repeats the checks and does nothing if the database is already
valid. It accepts only the four original files recorded in
`assets/trackpad-repair/manifest.json`, verifies their SHA-256 checksums and that
no Ubuntu package owns them, and validates a temporary copy of the database
before making changes. The obsolete files are:

- `30-vendor-starlabs.quirks`
- `50-framework.quirks`
- `50-system-prestigio.quirks`
- `50-system-purism.quirks`

It appends `.disabled-trackpad-repair` to their filenames, validates again, and
restores the filenames if validation fails. No files are deleted or arbitrary
pressure settings added. This is a deliberately narrow repair, not a general
cleanup of unowned files; different files need separate investigation.

Save your work, log out/in, then test normal movement, click-drag, and scrolling.
Restoring the database also restores device-specific quirks for other devices,
so check your mouse/tablet as well. The three-finger-drag helper is independent.

To undo this repair (including restoring the original parser defect):

```sh
sudo python3 scripts/trackpad-quirks.py undo
```

Log out/in again afterward. Existing backups made by the original repair are
compatible, so this command also provides rollback for that earlier fix.

Tests run only against temporary fixtures:

```sh
python3 assets/trackpad-repair/test_repair.py
```

See the [original symptom report](https://askubuntu.com/questions/1534991/how-can-i-make-my-apple-magic-trackpad-2-work-well-with-ubuntu-24-04-as-it-did-i)
and [libinput's quirks documentation](https://wayland.freedesktop.org/libinput/doc/latest/device-quirks.html).
