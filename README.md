# kernel_vibe_coding

Kernel scripts, tools and runbooks for every machine here, Intel and ARM, in one place. Most of it was built and written with Claude Code.

| Directory | Machines | What's in it |
|---|---|---|
| [intel/](intel/) | Yoga 9i (Raptor Lake-P), `gpu` (i7-5820K + RTX 3050) | mainline build script, hardware audit script, install runbook (stripped modules, GRUB default, NVIDIA DKMS) |
| [intel/](intel/) | `build` (i7-3770, Ivy Bridge) | boot options tuned for build throughput, a benchmark ([intel/docs/BUILD-BOX-TUNING.md](intel/docs/BUILD-BOX-TUNING.md)) |
| [intel/](intel/) | Yoga 7 14IRL8 (`debian13u`, i5-1335U) | mitigations compiled out, `-march=native`, `localmodconfig` module list, before/after numbers ([intel/docs/YOGA7-TUNING.md](intel/docs/YOGA7-TUNING.md)) |
| [arm/](arm/) | Lenovo Yoga C630 (SDM850), Samsung Galaxy Book Go (7c Gen 2) | Debian on Windows-on-ARM: boot menus, DTB patches, firmware staging, Wi-Fi/audio/BT fixes, systemd units, recovery runbooks |

The Pixel 3a (`sargo`, msm-4.9) kernel, its eBPF backport tooling and the LineageOS 24.0 build and install scripts live in [xbill9/android_kernel_google_msm-4.9](https://github.com/xbill9/android_kernel_google_msm-4.9) (`backport-tools/`), cloned at `~/android_kernel_google_msm-4.9`. `~/bin/sargo-build` and `~/bin/sargo-install` link into that tree.

## Layout

```
FIXES.md                    every problem the kernel loop found, open or fixed, and how each fix was checked
Makefile                    make install | install-scripts | feedback | loop | docs  (run `make` for the list)
tools/check-doc-links.py    broken local links and repo paths in the markdown
intel/
  scripts/kernel-build      pull ~/linux, olddefconfig, build, stripped install, GRUB default (--no-pull --no-install --reboot)
  scripts/kernel-boot-check after a reboot: running kernel is the installed build, then the boot logs
  scripts/kernel-log-compare this boot's logs against the last boot of another build: new, gone, counts
  scripts/hw-update         Claude audit of missing drivers, firmware and hardware tools (-p: report only)
  docs/KERNEL-INSTALL.md    build -> stripped install -> GRUB default -> NVIDIA DKMS; known 7.4-rc2 issues
  docs/BUILD-BOX-TUNING.md  the `build` box: throughput boot options, before/after numbers
  docs/YOGA7-TUNING.md      Yoga 7 14IRL8: no mitigations, native CPU, only its own modules; numbers, how to add a module
  config/yoga7-14irl8.lsmod module list its localmodconfig is built from
  grub/90-build-perf.cfg    GRUB drop-in with those options
  bench/build-box-bench     syscall cost and timed tinyconfig builds
arm/
  README.md, CLAUDE.md      per-machine overview and the "don't break the boot" rules
  c630/                     Yoga C630: RECOVERY, HARDWARE, FIRMWARE, QUIRKS, WIFI, MODEM, LOG; scripts/, system/, stick/ (GRUB 2.12 + DTB)
  galaxy-book-go/           Galaxy Book Go: DEBIAN, SID, ACPI, FIRMWARE; scripts/ (gbgo-*), system/, initramfs/, efi-shell/, win11-stick/
  setup/new-machine.sh      pull Claude Code config and git identity onto a fresh install
```

## Quick start

```sh
git clone https://github.com/xbill9/kernel_vibe_coding
cd kernel_vibe_coding
make install-scripts               # symlink the scripts into ~/bin
make install                       # build and install; see intel/docs/KERNEL-INSTALL.md
# reboot, then
make feedback                      # build ID check, then the boot logs
```

On an ARM laptop, start with that machine's `README.md` and `RECOVERY.md` before touching the boot chain.

## Sources

Copied on 2026-11-15 from:

| Here | From |
|---|---|
| `intel/scripts/` | `~/bin` (`kernel-build`, `hw-update`) |
| `intel/docs/` | kernel install notes kept by Claude Code on the Yoga 9i |
| `arm/` | [xbill9/linux-arm-adventures](https://github.com/xbill9/linux-arm-adventures) at `1d1cece`, without `articles/` and `backups/` |

Proprietary firmware and ACPI dumps stay local and are git-ignored (see `arm/.gitignore`).
