#!/bin/sh
# Install the read-only H5GG h5frida test HTML into a user-accessible script directory.
# Does not change H5GG.app, frida-server, packages, signatures, or processes.
set -eu
URL='https://raw.githubusercontent.com/AMWss/rea/65133a48d9b58d68b868d40fdb39e816d11147cf/scripts/ipad/h5frida-test.html'
target=''
for d in \
  /var/mobile/Media/DCIM/VMGG/H5Scripts \
  /var/mobile/Media/DCIM/H5Scripts \
  /var/mobile/Media/H5Scripts \
  /var/mobile/Documents/H5Scripts \
  /var/mobile/Media/Downloads \
  /var/mobile/Media
do
  if [ -d "$d" ] && [ -w "$d" ]; then target="$d"; break; fi
done
if [ -z "$target" ]; then
  printf '%s\n' 'No writable destination found. No changes made.' >&2
  exit 1
fi
dest="$target/h5frida-server-probe.html"
tmp="$target/.h5frida-server-probe.$$"
trap 'rm -f "$tmp"' EXIT HUP INT TERM
printf 'Downloading the diagnostic page to %s\n' "$target"
curl -fL --connect-timeout 15 --max-time 120 "$URL" -o "$tmp"
if [ ! -s "$tmp" ]; then printf 'Empty download, refusing install.\n' >&2; exit 1; fi
if [ -e "$dest" ]; then
 backup="$dest.bak.$(date '+%Y%m%d-%H%M%S')"
 cp -p "$dest" "$backup"
 printf 'Existing page backed up as %s\n' "$backup"
fi
mv "$tmp" "$dest"
chmod 0644 "$dest"
if [ "$(id -u)" = 0 ]; then chown mobile:mobile "$dest" 2>/dev/null || true; fi
printf '\nInstalled: %s\n' "$dest"
printf 'Open this HTML through H5GG script selector and tap the test button.\n'
printf 'It does not call loadGadget, attach to any process, or change memory.\n'
