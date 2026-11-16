# CLAUDE.md

Kernel scripts and runbooks for Intel (`intel/`), Windows-on-ARM laptops (`arm/`) and the Pixel 3a kernel (`android/`). `arm/CLAUDE.md` holds the boot-safety rules for the ARM laptops; read it before any change there.

- Kernel installs on x86 follow `intel/docs/KERNEL-INSTALL.md`: `INSTALL_MOD_STRIP=1`, make the new build the GRUB default, clean-env DKMS on NVIDIA machines.
- After a reboot, run `kernel-boot-check` before recording any result (exit 0 match, 1 mismatch, 2 no install record). `tainted = 0` alone does not prove the new build is running: suspend and resume keep the old kernel.
- `make install` builds and installs the kernel (`NOPULL=1` skips the pull), `make feedback` runs `kernel-boot-check`, `make loop` runs the build ID check then `kernel-log-compare` (this boot's logs against the last boot of another build; exit 1 on new kernel errors), `make docs` checks markdown links and rebuilds plus preflights the article. Run `make` for the list.
- `~/bin/kernel-build`, `kernel-boot-check`, `hw-update` and `sargo-build` are symlinks into the repo (`make install-scripts`), so edits are live at once. `~/bin/sargo-install` comes from `~/android_kernel_google_msm-4.9`, not `android/sargo/`.
- Scripts: `arm/` is POSIX `#!/bin/sh`; `intel/` and `android/` are bash (`set -euo pipefail` in `intel/`). Each starts with a usage/env header comment that `-h` prints.
- `articles/<slug>/` holds published articles. `links.txt` records the live URLs; keep it current after each publish.
- Mark anything not verified as untested.
- Never commit proprietary firmware, ACPI dumps, kernels or initrds.
- Commit straight to `main` and push. Subject prefixes: `intel:`, `Article:`, `C630:` (machine name for other `arm/` machines).
