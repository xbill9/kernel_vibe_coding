# kernel_vibe_coding

Kernel scripts, tools and runbooks for every machine here, Intel and ARM, in one place. Most of it was built and written with Claude Code.

| Directory | Machines | What's in it |
|---|---|---|
| [intel/](intel/) | Yoga 9i (Raptor Lake-P), `gpu` (i7-5820K + RTX 3050) | mainline build script, hardware audit script, install runbook (stripped modules, GRUB default, NVIDIA DKMS) |
| [arm/](arm/) | Lenovo Yoga C630 (SDM850), Samsung Galaxy Book Go (7c Gen 2) | Debian on Windows-on-ARM: boot menus, DTB patches, firmware staging, Wi-Fi/audio/BT fixes, systemd units, recovery runbooks |
| [android/](android/) | Pixel 3a (`sargo`, msm-4.9) | eBPF backport tooling for the LineageOS 4.9 kernel, LineageOS 24.0 build and phone install scripts |

## Layout

```
intel/
  scripts/kernel-build      pull ~/linux, olddefconfig, build, install (--no-pull --no-install --reboot)
  scripts/hw-update         Claude audit of missing drivers, firmware and hardware tools (-p: report only)
  docs/KERNEL-INSTALL.md    build -> stripped install -> GRUB default -> NVIDIA DKMS; known 7.4-rc2 issues
arm/
  README.md, CLAUDE.md      per-machine overview and the "don't break the boot" rules
  c630/                     Yoga C630: RECOVERY, HARDWARE, FIRMWARE, QUIRKS, WIFI, MODEM, LOG; scripts/, system/, stick/ (GRUB 2.12 + DTB)
  galaxy-book-go/           Galaxy Book Go: DEBIAN, SID, ACPI, FIRMWARE; scripts/ (gbgo-*), system/, initramfs/, efi-shell/, win11-stick/
  setup/new-machine.sh      pull Claude Code config and git identity onto a fresh install
android/
  backport-tools/           series lists, missing_fixes.py, resolve.py, build/next scripts, BPF probes, lineage-23.2/ and lineage-24.0/
  sargo/sargo-build         sync the xbill9 forks into the LineageOS 24.0 tree and build
  sargo/sargo-install       flash the newest build onto an attached Pixel 3a and restore GApps
```

## Quick start

```sh
git clone https://github.com/xbill9/kernel_vibe_coding
export PATH=$PWD/kernel_vibe_coding/intel/scripts:$PATH
kernel-build --no-install          # then follow intel/docs/KERNEL-INSTALL.md
```

On an ARM laptop, start with that machine's `README.md` and `RECOVERY.md` before touching the boot chain.

## Sources

Copied on 2026-11-15 from:

| Here | From |
|---|---|
| `intel/scripts/` | `~/bin` (`kernel-build`, `hw-update`) |
| `intel/docs/` | kernel install notes kept by Claude Code on the Yoga 9i |
| `arm/` | [xbill9/linux-arm-adventures](https://github.com/xbill9/linux-arm-adventures) at `1d1cece`, without `articles/` and `backups/` |
| `android/backport-tools/` | [xbill9/android_kernel_google_msm-4.9](https://github.com/xbill9/android_kernel_google_msm-4.9) at `dcaaefafd8ac` |
| `android/sargo/` | `~/bin` (`sargo-build`, `sargo-install`) |

Proprietary firmware and ACPI dumps stay local and are git-ignored (see `arm/.gitignore`).
