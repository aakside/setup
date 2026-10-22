#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSET="$DIR/../assets/three-finger-drag"
action=${1:-install}
case "$action" in
  status|disable) exec python3 "$ASSET/manage.py" "$action" ;;
  install|build|test) ;;
  *) echo "Usage: $0 install|build|test|status|disable" >&2; exit 2 ;;
esac
if [ "$(uname -s)" != Linux ]; then
  echo 'This helper is for Linux, not macOS.' >&2; exit 1
fi
if [ "$action" = install ]; then
  if [ "$(id -u)" = 0 ] || [ "${XDG_SESSION_TYPE:-}" != wayland ] ||
      [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]] ||
      ! systemctl --user is-active --quiet org.gnome.Shell@ubuntu.service; then
    echo 'Install as your desktop user in an active Ubuntu GNOME Wayland session.' >&2
    exit 1
  fi
fi
# A header override supports building against an extracted, matching Ubuntu
# development package without installing it (useful with stale manual headers).
if [ -n "${LIBINPUT_INCLUDE_DIR:-}" ]; then
  cflags=("-I$LIBINPUT_INCLUDE_DIR")
else
  if ! pkg-config --atleast-version=1.28 libinput; then
    echo 'Requires libinput >=1.28; on supported Ubuntu: sudo apt install build-essential pkg-config libinput-dev' >&2
    exit 1
  fi
  read -r -a cflags <<< "$(pkg-config --cflags libinput)"
fi
mkdir -p "$ASSET/build"
gcc -std=gnu11 -O2 -Wall -Wextra -Werror -fPIC -shared \
  -Wl,-z,relro,-z,now "${cflags[@]}" "$ASSET/enable-apple-drag.c" \
  -o "$ASSET/build/libapple-three-finger-drag.so" -ldl -pthread
gcc -std=gnu11 -O2 -Wall -Wextra -Werror "${cflags[@]}" \
  "$ASSET/probe.c" -o "$ASSET/build/probe" -l:libinput.so.10
(cd "$ASSET/build" && sha256sum libapple-three-finger-drag.so > library.sha256)
if [ "$action" = test ] || [ "$action" = install ]; then
  gcc -shared -fPIC -Wall -Wextra -Werror "${cflags[@]}" \
    "$ASSET/test-mock.c" -o "$ASSET/build/libmock.so"
  gcc -Wall -Wextra -Werror "${cflags[@]}" "$ASSET/test-driver.c" \
    -L"$ASSET/build" -lmock '-Wl,-rpath,$ORIGIN' -o "$ASSET/build/test"
  LD_PRELOAD="$ASSET/build/libapple-three-finger-drag.so" "$ASSET/build/test"
fi
if [ "$action" = install ]; then
  exec python3 "$ASSET/manage.py" install
fi
