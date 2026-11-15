<!-- Claude Code memory file from yoga9i, copied 2026-11-15. Verbatim except the originSessionId line. -->
---
name: kernel-install-nvidia-dkms
description: "On host \"gpu\", `sudo make install` breaks the NVIDIA DKMS build; run dkms/initramfs/grub by hand in a clean env"
metadata:
  node_type: memory
  type: project
  modified: 2026-11-13T19:07:42.279Z
---

On the `gpu` box (i7-5820K, RTX 3050, NVIDIA open module 615.78.08 via DKMS, headless over SSH), `sudo make install` in ~/linux fails: the kernel's install target exports KERNELRELEASE, the /etc/kernel/postinst.d/dkms hook inherits it, and NVIDIA's Makefile then does `include $(src)/Kbuild` with empty src ("/Kbuild: No such file"). run-parts stops there, so initramfs-tools and zz-update-grub are skipped too.

**Why:** observed 2026-11-13 installing 7.4.0-rc2-xbill-hsw+; verified the clean-env rerun succeeds.

**How to apply:** after `sudo make modules_install`, copy bzImage/System.map/.config to /boot as vmlinuz-K/System.map-K/config-K, then with `env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin HOME=/root`: `dkms remove nvidia/<ver> -k K` then `dkms install nvidia/<ver> -k K` (a plain `dkms install --force` reinstalls the already-built .ko from /var/lib/dkms without recompiling: on 2026-11-13 build #7 got #6's modules after a .config change, and nvidia.ko failed with "x86/modules: Invalid relocation target, existing value is nonzero" in .rela.gnu.linkonce.this_module; MODVERSIONS is off so vermagic alone does not catch it), `update-initramfs -c|-u -k K`, `update-grub`. Do not call arch/x86/boot/install.sh directly (falls to LILO path, copies nothing). On this box GRUB_DEFAULT=0 and the newest kernel sorts first, so the new build is already the default; confirm entry 0's `linux` line in /boot/grub/grub.cfg (see [[kernel-install-set-default]]: the user wants the latest build as default, no asking). Tuned config uses LOCALVERSION -xbill-hsw with CONFIG_RUST=y and nova-core deliberately off (would contend with nvidia for GA106).

**Rebuilding for an already-registered kernel:** `dkms install nvidia/<ver> -k K --force` only reinstalls the cached build in /var/lib/dkms/... (same file size, still fails). After any rebuild of the same kernel release, run `dkms build nvidia/<ver> -k K --force` first, then `dkms install ... --force`. A stale module fails with `modprobe: Exec format error` and repeated `x86/modules: Invalid relocation target` in dmesg (seen on yogagpu 2026-11-13, 7.4.0-rc2-yoga-ai+, NVIDIA 620.70.06; fixed by the forced build).
