<!-- Claude Code memory file from yoga9i, copied 2026-11-15. Verbatim except the originSessionId line. -->
- [Kernel install sets GRUB default](kernel-install-set-default.md) — new build becomes the boot default
- [Kernel install + NVIDIA DKMS](kernel-install-nvidia-dkms.md) — `make install` breaks DKMS; manual clean-env steps; `dkms build --force` before reinstall
- [7.4 ASoC rtd flex fix](kernel-7.4-soc-rtd-flex-fix.md) — no-mic fix now upstream (d00ba321499c); local edit dropped
- [Strip modules on kernel install](kernel-install-strip-modules.md) — use INSTALL_MOD_STRIP=1 -j$(nproc) or initrd hits 640MB
- [kernel_vibe_coding repo](kernel-vibe-coding-repo.md) — cross-platform kernel scripts/runbooks repo; add new kernel work there
