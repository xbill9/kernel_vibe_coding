# CLAUDE.md

Kernel scripts and runbooks for Intel (`intel/`), Windows-on-ARM laptops (`arm/`) and the Pixel 3a kernel (`android/`). `arm/CLAUDE.md` holds the boot-safety rules for the ARM laptops; read it before any change there.

- Kernel installs on x86 follow `intel/docs/KERNEL-INSTALL.md`: `INSTALL_MOD_STRIP=1`, make the new build the GRUB default, clean-env DKMS on NVIDIA machines.
- Mark anything not verified as untested.
- Never commit proprietary firmware, ACPI dumps, kernels or initrds.
- Commit straight to `main` and push.
