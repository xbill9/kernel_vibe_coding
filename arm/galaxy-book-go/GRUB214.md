# Galaxy Book Go: GRUB 2.14 (2026-11-19)

Since 2026-11-19 09:16 the Galaxy Book Go runs **GRUB 2.14-5 and shim 16.1-2 from sid**, unheld. Until then every `grub*` and `shim*` package was held at 2.12-9+deb13u2 and 16.1-2~deb13u1, because sid's GRUB 2.14 blacked out every kernel on the C630 ([../c630/INCIDENT-2026-10-10.md](../c630/INCIDENT-2026-10-10.md)). **Not yet verified across a reboot: no kernel has booted through GRUB 2.14 on this machine.**

## Boot chain

| File | Now | Before |
|---|---|---|
| `EFI/BOOT/BOOTAA64.EFI` (shim, what the firmware runs) | `01ee1ab90c874adc…` shim 16.1-2 | `e5446d2a09dfae3f…` |
| `EFI/BOOT/grubaa64.efi` | `503d697c5d911946…` GRUB 2.14-5 | `3db6ed77b8de1677…` GRUB 2.12 |
| `EFI/debian/` | same two images | same as `EFI/BOOT` |
| `EFI/grub212/grubaa64.efi` | `3db6ed77b8de1677…` GRUB 2.12, the fallback | — |
| `/boot/grub/arm64-efi` | 2.14 modules | 2.12 modules |

The firmware exposes no EFI variables (`/sys/firmware/efi/efivars` is empty), so it boots the removable path `EFI/BOOT`. Debconf `grub2/force_efi_extra_removable` is `true`, so the package's `grub-install` writes `EFI/BOOT` as well as `EFI/debian`. `grub2/update_nvram` is set to `false`, since there are no variables to write.

## GRUB 2.12 fallback

[scripts/00_grub212](scripts/00_grub212) (`/etc/grub.d/`) does two things on every `update-grub`:

- Adds the menu entry **`GRUB 2.12 fallback`** (id `gbgo-grub212`), which chainloads `EFI/grub212/grubaa64.efi`.
- Writes `EFI/grub212/grub.cfg`, a menu for 2.12 with built-in commands only (one entry per kernel, the `GRUB_DEFAULT` kernel first). 2.12 must not load the 2.14 modules in `/boot/grub/arm64-efi`. So the first lines of `grub.cfg` send any GRUB without `feature_gcry_hw_accel` (2.12 lacks it, 2.14 defines it) to that menu, before `00_header` loads a module.

Both images have `linux`, `initrd`, `devicetree`, `search`, `configfile` and `chainloader` built in (`strings`). shim 16.1-2 requires GRUB SBAT generation 5; the 2.12 image is `grub,5`. Whether Secure Boot is on is unknown.

[scripts/gbgo-boot-verify](scripts/gbgo-boot-verify) checks that `EFI/BOOT` holds the installed packages' images, that the 2.12 fallback image is unchanged, and that its menu has the default kernel.

## Earlier test (2026-11-18)

GRUB 2.14 run from the ESP, chainloaded from 2.12, packages held. Run 1: failed, cause unknown. Run 2: 2.14 started and reached its test menu (`g214_step=214-menu`); the test kernel never booted, and the next boot was the 2.12 default. Whether 2.14 can hand over to a kernel here is therefore unknown. The test is retired: `00_grub214` and its service removed, `EFI/grub214` deleted.

## If it does not boot

| Symptom | Do |
|---|---|
| 2.14 menu shows, kernel goes black | hold power 10 s, then pick **`GRUB 2.12 fallback`** in the menu |
| No menu at all | Debian stick on the hub (see [SID.md](SID.md#recovery)), then copy `esp/` from `/boot/gbgo-known-good/grub212-2026-11-19/` back to `/boot/efi` |

Backup taken before the upgrade: `/boot/gbgo-known-good/grub212-2026-11-19/` (`esp/`, `grub/`, `etc-default-grub`, `SHA256SUMS`).
