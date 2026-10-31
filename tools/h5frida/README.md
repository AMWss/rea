# h5frida Rootless build lab (experimental)

Goal: build the **open-source H5GG h5frida plugin against Frida Core 17.25.0**, for the user's Dopamine Rootless iPad, WITHOUT changing the on-device working setup.

- Source: https://github.com/H5GG/H5GG/tree/main/pluginDemo/h5frida15.1.24
- Upstream plugin uses Objective-C++ (h5frida.mm), Theos, fishhook, Dobby, Frida Core, and has a bundled 15.1.24 static library.
- Target server on device: Frida 17.25.0, currently running on 127.0.0.1:27042 via FridaManager.
- This branch does not include redistributed binaries; the CI downloads official sources and development libraries.
- Build tries to use the newer 17.25.0 Frida Core devkit. **The old source may need Frida 17 API porting**; a failed CI job is a diagnostic, not a working dylib.
- Theos's `THEOS_PACKAGE_SCHEME=rootless` sets the Rootless installation scheme, but a valid dylib requires successful compilation, correct signatures/entitlements, API compatibility and on-device tests.
- The CI does not sign or install anything onto an iPad. Do NOT overwrite the existing H5GG plugin with an untested artifact.

To run manually, see `.github/workflows/h5frida-rootless-build.yml` (pushes to this branch run the job if GitHub Actions is enabled). Review build logs before downloading any binaries.

### Security and third-party licenses

This project references H5GG's source; preserve the upstream license notice and Frida/Dobby/ldid component notices as applicable. No reverse engineering of proprietary binaries is needed for the first attempt.

### Current task

1. Verify the old plugin can be compiled against Frida Core 17.25.0, updating changed C API functions as build logs indicate.
2. Preserve JS bridge exports expected by Unity5D Tool.
3. Add error propagation for Frida device and process enumeration.
4. Only after successful builds: produce unsigned build artifacts for independent signing and on-device testing; do not auto-install.
