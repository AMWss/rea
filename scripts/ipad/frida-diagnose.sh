#!/bin/sh
# Frida diagnostics v2 - read-only - for Dopamine Rootless
LC_ALL=C; export LC_ALL
sect() { printf '\n=== %s ===\n' "$1"; }
has() { command -v "$1" >/dev/null 2>&1; }
sect "Frida diagnostic v2"
date '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || true
id
sect "Frida CLI tools"
for t in frida-server frida frida-ps frida-ls-devices nc lsof netstat timeout; do
  if has "$t"; then printf '%s: %s\n' "$t" "$(command -v "$t")"; else printf '%s: absent\n' "$t"; fi
done
sect "Server version"
if has frida-server; then frida-server --version 2>&1 || true; else printf 'NOT FOUND\n'; fi
sect "Server process"
ps -A 2>&1 | grep -i '[f]rida' || printf 'No matching process\n'
sect "Loopback service port 27042"
if has lsof; then lsof -nP -iTCP:27042 2>&1 || true
elif has netstat; then netstat -an 2>&1 | grep '27042' || printf 'No matching listening socket\n'
else printf 'No lsof/netstat; inspect running frida-server -l parameters above\n'; fi
sect "Optional Frida CLI query via localhost"
if has frida-ps && has timeout; then
  timeout 8 frida-ps -H 127.0.0.1:27042 2>&1 | head -30 || true
elif has frida-ps; then
  printf 'frida-ps installed, but no timeout. Skipping possible hanging query.\n'
else printf 'frida-ps not installed; not required for h5frida.\n'; fi
sect "H5GG plugin and gadget config"
for p in /var/jb/Applications/h5ggapp.app/h5frida-15.1.24.dylib /var/jb/Applications/h5ggapp.app/frida-gadget-15.1.24.dylib /var/jb/Applications/h5ggapp.app/frida-gadget-15.1.24.config; do
  if [ -f "$p" ]; then ls -lh "$p"; else printf 'MISSING: %s\n' "$p"; fi
done
sect "Done"
printf 'Read-only checks complete. No changes made.\n'
