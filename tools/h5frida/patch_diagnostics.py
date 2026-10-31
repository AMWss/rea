#!/usr/bin/env python3
"""Patch upstream H5GG h5frida for Frida 17 diagnostic error propagation.

Only changes the checked-out build workspace. Original upstream repository untouched.
"""
from pathlib import Path
import sys

src=Path(sys.argv[1])
text=src.read_text(encoding="utf-8")

def change_once(old, new):
    global text
    count=text.count(old)
    if count!=1:
        raise SystemExit(f"Expected one occurrence of {old!r}, found {count}")
    text=text.replace(old,new,1)

change_once(
    "-(NSString*)coreVersion;\n",
    "-(NSString*)coreVersion;\n-(NSString*)diagnosticLastError;\n"
)
change_once(
    "@property FridaDeviceManager * manager;\n",
    "@property (nonatomic, copy) NSString* diagnosticError;\n@property FridaDeviceManager * manager;\n"
)
change_once(
    "@implementation h5frida\n",
    '@implementation h5frida\n-(NSString*)diagnosticLastError { return self.diagnosticError ?: @""; }\n'
)

start=text.index("-(NSArray*)enumerate_processes\n{")
end=text.index("-(NSDictionary*)get_frontmost_application",start)
body=text[start:end]
old="    NSMutableArray* procs = [[NSMutableArray alloc] init];"
assert body.count(old)==1
body=body.replace(old,"    self.diagnosticError = nil;\n"+old,1)
if 'g_printerr ("Failed to attach: %s\\n", error->message);' not in body:
    raise SystemExit("Missing legacy error message in process enumeration")
body=body.replace(
    'g_printerr ("Failed to attach: %s\\n", error->message);',
    'self.diagnosticError = [NSString stringWithUTF8String:(error->message ?: "unknown Frida error")];\n'
    '        g_printerr ("Frida process enumeration failed: %s\\n", error->message);'
)
text=text[:start]+body+text[end:]
src.write_text(text,encoding="utf-8")
print(f"Patched diagnosticLastError() into {src}")
