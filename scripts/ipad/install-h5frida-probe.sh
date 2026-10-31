#!/bin/sh
# H5GG read-only diagnostic page installer v2.
# Installs only a local HTML file; does not modify jailbreak, Frida or H5GG.app.
set -eu
umask 077
URL='https://raw.githubusercontent.com/AMWss/rea/65133a48d9b58d68b868d40fdb39e816d11147cf/scripts/ipad/h5frida-test.html'
name='h5frida-server-probe.html'
target=''

# Optional explicit output directory for unusual path mappings.
if [ "$#" -gt 1 ]; then
  printf 'Usage: sh %s [output-directory]\n' "$0" >&2
  exit 2
fi
if [ "$#" -eq 1 ]; then
  if ! mkdir -p "$1" 2>/dev/null || [ ! -w "$1" ]; then
    printf 'Cannot use requested directory: %s\n' "$1" >&2
    exit 1
  fi
  target=$1
else
  for d in \
    /var/mobile/Media/DCIM/VMGG/H5Scripts \
    /private/var/mobile/Media/DCIM/VMGG/H5Scripts \
    /rootfs/private/var/mobile/Media/DCIM/VMGG/H5Scripts \
    /var/mobile/Media/DCIM/H5Scripts \
    /private/var/mobile/Media/DCIM/H5Scripts \
    /rootfs/private/var/mobile/Media/DCIM/H5Scripts \
    /var/mobile/Media/H5Scripts \
    /private/var/mobile/Media/H5Scripts \
    /rootfs/private/var/mobile/Media/H5Scripts
  do
    if [ -d "$d" ] && [ -w "$d" ]; then target=$d; break; fi
  done
  # Previous installer required the complete folder to exist.
  if [ -z "$target" ]; then
    for media in /var/mobile/Media /private/var/mobile/Media /rootfs/private/var/mobile/Media; do
      if [ -d "$media" ] && [ -w "$media" ]; then
        d="$media/DCIM/VMGG/H5Scripts"
        if mkdir -p "$d" 2>/dev/null && [ -w "$d" ]; then target=$d; break; fi
        d="$media/H5Scripts"
        if mkdir -p "$d" 2>/dev/null && [ -w "$d" ]; then target=$d; break; fi
      fi
    done
  fi
  if [ -z "$target" ]; then
    for d in /var/mobile /private/var/mobile /rootfs/private/var/mobile "${HOME:-}" "$(pwd)"; do
      if [ -n "$d" ] && [ -d "$d" ] && [ -w "$d" ]; then target=$d; break; fi
    done
  fi
fi
if [ -z "$target" ]; then
  printf 'No writable destination (even HOME). Diagnostic only:\n' >&2
  id >&2 || true
  pwd >&2 || true
  ls -ld /var/mobile /private/var/mobile /rootfs/private/var/mobile "${HOME:-/NONEXISTENT}" 2>&1 || true
  exit 1
fi
printf 'Chosen output directory: %s\n' "$target"
tmp=$(mktemp "$target/.h5frida-probe.XXXXXX") || exit 1
trap 'rm -f "$tmp"' EXIT HUP INT TERM
curl -fL --connect-timeout 15 --max-time 120 "$URL" -o "$tmp"
if [ ! -s "$tmp" ] || ! grep -q 'h5frida 越狱模式诊断' "$tmp"; then
  printf 'Downloaded data is empty or not the expected test HTML. Aborting.\n' >&2
  exit 1
fi
dest="$target/$name"
if [ -L "$dest" ]; then
  printf 'Refusing to replace a symbolic link: %s\n' "$dest" >&2
  exit 1
fi
if [ -e "$dest" ]; then
  backup="$dest.bak.$(date '+%Y%m%d-%H%M%S')"
  cp -p "$dest" "$backup"
  printf 'Existing page backed up: %s\n' "$backup"
fi
mv "$tmp" "$dest"
chmod 0644 "$dest"
if [ "$(id -u)" = 0 ]; then chown mobile:mobile "$dest" 2>/dev/null || true; fi
printf '\nSUCCESS: %s\n' "$dest"
printf 'Open this HTML in H5GG and tap the test button. No Gadget load, attach, or memory modifications.\n'
if [ "$target" = "${HOME:-/NONEXISTENT}" ]; then
  printf 'NOTE: Saved in root HOME fallback. If H5GG cannot browse it, use Filza to move the HTML to the scripts folder.\n'
fi
