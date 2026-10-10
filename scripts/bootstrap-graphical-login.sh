#!/usr/bin/env bash
set -euo pipefail

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot detect Linux distribution: /etc/os-release is missing" >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

install_ubuntu() {
  if [[ "${VERSION_ID:-}" != "26.04" ]]; then
    echo "This bootstrap currently targets Ubuntu 26.04; detected ${VERSION_ID:-unknown}." >&2
    exit 1
  fi

  sudo apt-get update
  sudo apt-get install -y ca-certificates wget dbus dbus-user-session greetd accountsservice polkitd gnome-keyring

  if [[ ! -f /usr/share/keyrings/nickh-archive-keyring.gpg && ! -f /etc/apt/trusted.gpg.d/nickh-archive-keyring.gpg ]]; then
    tmp="$(mktemp --suffix=.deb)"
    trap 'rm -f "$tmp"' EXIT
    wget -O "$tmp" https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb
    sudo dpkg -i "$tmp"
  fi

  sudo wget -qO /etc/apt/sources.list.d/noctalia-resolute.sources \
    https://pkg.noctalia.dev/deb/noctalia-resolute.sources

  sudo apt-get update
  sudo apt-get install -y noctalia-greeter
}

install_fedora() {
  local major="${VERSION_ID%%.*}"
  if [[ -z "$major" || "$major" -lt 44 ]]; then
    echo "Noctalia Greeter packages require Fedora 44+; detected ${VERSION_ID:-unknown}." >&2
    exit 1
  fi

  sudo dnf install -y \
    --nogpgcheck \
    --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
    terra-release

  sudo dnf install -y greetd noctalia-greeter accountsservice polkit gnome-keyring
}

case "${ID:-}" in
  ubuntu)
    install_ubuntu
    ;;
  fedora)
    install_fedora
    ;;
  *)
    echo "Unsupported distribution for bootstrap: ${PRETTY_NAME:-${ID:-unknown}}" >&2
    echo "Supported by this repository: Ubuntu 26.04 and Fedora 44+." >&2
    exit 1
    ;;
esac

if ! command -v greetd >/dev/null 2>&1; then
  echo "greetd was not installed correctly" >&2
  exit 1
fi

if ! command -v noctalia-greeter-session >/dev/null 2>&1; then
  echo "noctalia-greeter-session is missing from PATH" >&2
  exit 1
fi

if ! getent passwd greeter >/dev/null; then
  echo "The distribution packages did not create the 'greeter' account." >&2
  exit 1
fi

echo
echo "Bootstrap complete."
echo "Next:"
echo "  1. tack update system-manager"
echo "  2. make home-switch-desktop"
echo "  3. make system-switch"
echo "  4. sudo reboot"
