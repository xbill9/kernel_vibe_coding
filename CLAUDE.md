# CLAUDE.md

Kernel scripts and runbooks for Intel (`intel/`), Windows-on-ARM laptops (`arm/`) and the Pixel 3a kernel (`android/`). `arm/CLAUDE.md` holds the boot-safety rules for the ARM laptops; read it before any change there.

- Kernel installs on x86 follow `intel/docs/KERNEL-INSTALL.md`: `INSTALL_MOD_STRIP=1`, make the new build the GRUB default, clean-env DKMS on NVIDIA machines.
- After a reboot, run `kernel-boot-check` before recording any result (exit 0 match, 1 mismatch, 2 no install record). `tainted = 0` alone does not prove the new build is running: suspend and resume keep the old kernel.
- `~/bin/kernel-build` and `~/bin/kernel-boot-check` are symlinks into `intel/scripts/`, so edits are live at once. `~/bin/hw-update` and `~/bin/sargo-build` are separate copies, so update both when you change them. `~/bin/sargo-install` comes from `~/android_kernel_google_msm-4.9`, not `android/sargo/`.
- Scripts: `arm/` is POSIX `#!/bin/sh`; `intel/` and `android/` are bash (`set -euo pipefail` in `intel/`). Each starts with a usage/env header comment that `-h` prints.
- `articles/<slug>/` holds published articles. `links.txt` records the live URLs; keep it current after each publish.
- Mark anything not verified as untested.
- Never commit proprietary firmware, ACPI dumps, kernels or initrds.
- Commit straight to `main` and push. Subject prefixes: `intel:`, `Article:`, `C630:` (machine name for other `arm/` machines).
