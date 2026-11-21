# Galaxy Book Go: offline Debian 13 installer notes

Contributed by Knifethrower (2026-10-22, see [linux-arm-adventures#1](https://github.com/xbill9/linux-arm-adventures/issues/1)). What it took to install Debian 13.7 (XFCE) on the internal UFS **without network**, from one FAT32 USB stick, using this folder's DTB chain and scripts afterwards.

## Stick layout

FAT32, any label (here `GBGO`), GPT with one partition:

- `debian-13.7.0-arm64-DVD-1.iso` at the root: 3.99 GB, fits FAT32's 4 GiB file limit. DVD 1 has `task-xfce-desktop`, PipeWire, BlueZ, `firmware-qcom-soc` and `firmware-atheros`.
- The **hd-media** installer (`dists/trixie/main/installer-arm64/current/images/hd-media/vmlinuz` + `initrd.gz`). Its kernel must match the DVD's module set; for 13.7 both were 6.12.107+deb13.
- Boot loader: Debian's own **shim + signed GRUB** from the DVD's `EFI/boot/` (`bootaa64.efi` as `EFI/BOOT/BOOTAA64.EFI`, `grubaa64.efi` next to it). These are byte-identical to what ends up on the installed ESP.
- `/EFI/debian/grub.cfg`: Debian's signed GRUB reads `$prefix/grub.cfg` = `/EFI/debian/grub.cfg` on the boot drive first (the DVD keeps a stub there). Without it, GRUB drops to a `grub>` prompt. A stub that finds the stick by label:
  ```
  search --no-floppy --label GBGO --set=root
  set prefix=($root)/boot/grub
  configfile ($root)/boot/grub/grub.cfg
  ```
- The installer's device tree: the unpatched draft DTB, as this folder's original installer stick used. The patched DTB only goes onto the installed system.

Boot it with **Secure Boot off**, through a USB-C hub (as README.md says, direct USB boot is picky). A standalone (unsigned) `grub-mkstandalone` GRUB reset the laptop with Debian's kernel before any output, even with `earlycon`; Debian's shim + signed GRUB did not.

## Installer pitfalls and fixes

Kernel command line, besides `clk_ignore_unused pd_ignore_unused` and the `devicetree` line:

- `preseed/file=/hd-media/<dir>/preseed.cfg`: the stick is mounted at `/hd-media`.
- `shared/ask_device=/dev/disk/by-label/GBGO`: otherwise `iso-scan` mounts and searches **every** partition on the UFS (Windows included, dozens of partitions across the LUNs), which takes many minutes. `iso-scan/filename` is only an output in this version; it is not read.

Preseed lines that matter on this machine:

```
d-i netcfg/enable boolean false
d-i ethdetect/module_select select no ethernet card
d-i apt-setup/use_mirror boolean false
d-i grub-installer/force-efi-extra-removable boolean true
grub-efi-arm64 grub2/update_nvram boolean false
```

(no Ethernet; Wi-Fi only works after the first boot; EFI variables can't be written from Linux, so GRUB goes to the removable path `EFI/BOOT/BOOTAA64.EFI`, which the firmware boots by default once Windows Boot Manager is gone.)

**ESP formatting fails on the UFS.** partman-efi formats the ESP as **FAT16 on arm64** and forces 1-sector clusters on non-512-byte disks. The UFS has 4 KiB logical sectors, so FAT16 tops out at ~268 MB and every normal ESP (1 GB and the guided default were tried) fails with "Not enough or too many clusters". Fix, in `partman/early_command` (or by hand from the Alt+F2 shell before partitioning):

```
sed -i 's/new_efi_fs=fat16/new_efi_fs=fat32/' /lib/partman/commit.d/50format_efi
```

Then guided "use entire disk" works with a normal ESP.

**The stick is mounted read-only** (`iso-scan` mounts `/hd-media` with `-o ro`). A `late_command` script that logs to the stick must `mount -o remount,rw /hd-media` first, or log to `/tmp`: a failing `exec >> log` redirect silently ends the script, so none of the post-install setup runs.

**Not on DVD 1**, needed for Wi-Fi etc. (put the .debs on the stick and `dpkg -i` them in the target): `qrtr-tools`, `libqrtr1`, `rmtfs`, `protection-domain-mapper`, `tqftpserv`, `i2c-tools`, `libi2c0`, `systemd-zram-generator`.

## Kernel: audio needs 7.2

On Debian 13's 6.12 the audio DTB boots and the ADSP comes up, but every AFE command times out (`AFE set params failed -110`, `fail to start AFE port 14` on TERT_MI2S), so the card appears and stays silent. On **7.2.9 from trixie-backports** (`apt install -t trixie-backports linux-image-arm64`) the same DTB plays through the speakers. That's the same kernel version as the sid route in SID.md, without the full sid upgrade; `09_galaxy-book-go` picks up the new kernel automatically.
