#!/bin/sh
# Shengsheng iPad Diagnostics v1 - READ ONLY
# Designed for Dopamine Rootless / H5GG / h5frida checks.
# No downloads, installations, permission changes, or network listening.
LC_ALL=C
export LC_ALL
section() { printf '\n=== %s ===\n' "$1"; }
has() { command -v "$1" >/dev/null 2>&1; }
section "Diagnostic version"
printf 'ipad-diag v1 (read-only)\n'
date '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || true
section "Identity and kernel"
id 2>&1 || true
uname -smr 2>&1 || true
section "Jailbreak location"
ls -ld /var/jb 2>&1 || true
readlink /var/jb 2>&1 || true
section "Available tools"
for tool in sh curl dpkg dpkg-query sudo ldid codesign frida-server h5frida-setup python3 git; do
  if has "$tool"; then printf '%s: %s\n' "$tool" "$(command -v "$tool")"
  else printf '%s: not found\n' "$tool"; fi
done
section "Frida installed packages"
if has dpkg-query; then
  dpkg-query -W -f='\''${Package} ${Version} ${Architecture}\n'\'' '*frida*' 2>&1 || true
else
  printf 'dpkg-query unavailable\n'
fi
section "Frida processes"
if has ps; then
  ps -A 2>/dev/null | grep -i '[f]rida' || printf 'No matching process found\n'
else printf 'ps unavailable\n'; fi
section "Frida server candidate files"
for f in /var/jb/usr/sbin/frida-server /var/jb/usr/bin/frida-server /usr/sbin/frida-server /usr/bin/frida-server; do
  if [ -e "$f" ]; then ls -l "$f" 2>&1; fi
done
section "H5GG application bundles and plugin files"
found=0
for app in /var/jb/Applications/h5ggapp.app /Applications/h5ggapp.app; do
  if [ -d "$app" ]; then
    found=1
    ls -ldi "$app" 2>&1
    for file in h5frida-15.1.24.dylib frida-gadget-15.1.24.dylib frida-gadget-15.1.24.config; do
      if [ -f "$app/$file" ]; then ls -lh "$app/$file" 2>&1
      else printf 'Missing: %s/%s\n' "$app" "$file"; fi
    done
  fi
done
if [ "$found" = 0 ]; then printf 'No standard H5GG app bundle found\n'; fi
section "H5Frida installer status"
if has h5frida-setup; then
  h5frida-setup --status 2>&1 || true
else printf 'Not installed\n'; fi
section "End"
printf 'No changes made. Review output for private paths before sharing.\n'
