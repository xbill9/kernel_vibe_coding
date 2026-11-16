# Fixes

One entry per problem found in the kernel loop, open or fixed: what broke, why, what fixed it, and how the fix was checked. ARM bring-up history stays in `arm/c630/LOG.md`, and the Pixel 3a backport's upstream fixes in `backport-tools/` of [android_kernel_google_msm-4.9](https://github.com/xbill9/android_kernel_google_msm-4.9).

| Status | Meaning |
|---|---|
| 🟢 | fixed, and the fix was checked on the machine named |
| ⚠️ | fix committed, not yet checked on a machine that has the problem |
| ❌ | open |

## Index

| # | Status | Machine | Problem | Fix |
|---|---|---|---|---|
| F13 | ❌ | debian (Yoga C630) | `make loop` stops: no install record | none yet |
| F12 | ❌ | debian (Yoga C630) | `Bluetooth: hci0: unexpected event for opcode 0x0000` | none yet |
| F11 | 🟢 | debian (Yoga C630) | built-in Wi-Fi appears ~95 s after boot | `34d4e11` (mask) |
| F10 | ❌ | debian (Yoga 7 14IRL8) | `Driver 'pcspkr' is already registered` at boot | none yet |
| F9 | ❌ | debian (Yoga 7 14IRL8) | systemd `bpf-restrict-fs` cannot load: no kernel BTF | none yet |
| F8 | 🟢 | samsung13 | `make loop` reports hashed `%p` pointers as new error lines | `94316e9` |
| F7 | ❌ | yoga9i | Wacom digitizer: `device returned incorrect report (0 vs 11 expected)` | none yet |
| F6 | ⚠️ | not yoga9i | runtime-PM udev rule logs ~40 `Could not chase` lines per boot | `7ed46de` |
| F5 | ⚠️ | gpu, yogagpu | NVIDIA DKMS build fails under `make install` | `1c9191f` |
| F4 | 🟢 | yoga9i | boot checks read an older build of the same release | `d045c39` |
| F3 | 🟢 | yoga9i | new build installed but not the GRUB default | `12fc365` |
| F2 | 🟢 | yoga9i | initrd 641MB from unstripped modules | `12fc365` |
| F1 | 🟢 | yoga9i | 7.4-rc2: no sound card, no microphone | upstream `d00ba321499c` |

## Adding an entry

Take the next number and add it to the top of the index and as a section below. A new line from `make loop` gets an entry once it has been looked at, even before there is a fix. Fill in every field; write `untested` instead of leaving one out.

```
### F<n> — <problem in a few words>

- Status: ❌ | ⚠️ | 🟢
- Machine / kernel: <host>, <release> <build ID>
- Symptom: <log line or behaviour, verbatim>
- Cause: <what was found, or "unknown">
- Fix: <commit, upstream commit, or config change>
- Checked: <command and result, with date>, or "untested"
```

---

### F13 — `make loop` stops on the C630: no install record

- Status: ❌ open
- Machine / kernel: debian (Yoga C630), 7.4.0-rc3 `#9`
- Symptom: `no install record at ~/.local/state/kernel-build/installed; install with kernel-build first`, then `make: *** [Makefile:46: loop] Error 2`
- Cause: on the C630, `~/bin/kernel-build` is a local copy (1732 bytes, 2026-11-14), not the `intel/scripts/` symlink. It stamps no build ID and writes no install record. It also leaves `/boot/vmlinux-<rel>` with no `vmlinuz` and no DTB, so `c630-menu` skips the kernel until both are added by hand (`arm/c630/LOG.md`, 2026-11-16).
- Fix: none. Candidate: link the repo's `kernel-build` here (`make install-scripts`) with an arm64 install step: `Image` → `vmlinuz-<rel>`, DTB → `/usr/lib/linux-image-<rel>/`, `c630-menu`, never the default. Untested.
- Checked: 2026-11-16, build checked by hand instead: `uname -v` `#9 ... Mon Nov 16 12:42:29`, installed 12:43. `intel/scripts/kernel-log-compare` run on its own against `#8`.

### F12 — Bluetooth `unexpected event for opcode 0x0000`

- Status: ❌ open, harmless as far as seen
- Machine / kernel: debian (Yoga C630), 7.4.0-rc3 `#9` against `#8` (boot -1)
- Symptom: `Bluetooth: hci0: unexpected event for opcode 0x0000` at 10.8 s, once, after `QCA setup on UART is completed` and the second `setting up wcn399x`
- Cause: unknown. Not seen in the 8 earlier boots (rc3 `#8`, rc2, Debian 7.2.9), so it may be a one-off.
- Fix: none
- Checked: 2026-11-16, `bluetoothctl show`: `Powered: yes`; `hci0 UP RUNNING`. Pairing untested.

### F11 — C630 built-in Wi-Fi appears ~95 s after boot

- Status: 🟢
- Machine / kernel: debian (Yoga C630), every kernel (Debian 7.2.9, 7.4.0-rc2, 7.4.0-rc3)
- Symptom: no `wlan0` until about 100 s. `Timed out waiting for device dev-disk-by\x2dpartlabel-persist.device` at 95.9 s, then `Started tqftpserv.service`, then `ath10k_snoc ... qmi chip_id` at 97.7 s.
- Cause: `tqftpserv-populate-readwrite.service` (from the `tqftpserv` package) is `Before=tqftpserv.service` and `Requires=` a `persist` partition the C630 does not have. `tqftpserv` serves the WLAN firmware to the modem. See `arm/c630/WIFI.md`.
- Fix: `34d4e11`, `systemctl mask tqftpserv-populate-readwrite.service`
- Checked: 2026-11-16, 7.4.0-rc3 `#9`: `ath10k_snoc ... qmi chip_id` at 13.0 s, `wlan0: associated` at 20.8 s.

### F10 — `pcspkr` driver registered twice

- Status: ❌ open, harmless as far as seen
- Machine / kernel: debian (Lenovo Yoga 7 14IRL8), 7.4.0-rc3 `#6-c3d1b926` against 7.3.4+deb14-amd64 `#1` (boot -1)
- Symptom: `Error: Driver 'pcspkr' is already registered, aborting...`, once per boot, just after `input: PC Speaker as /devices/platform/pcspkr/input/input23`
- Cause: `pcspkr` (input) and `snd_pcsp` (ALSA) both register a platform driver named `pcspkr` (`drivers/input/misc/pcspkr.c:126`, `sound/drivers/pcsp/pcsp.c:196`). In this build's `modules.alias` both modules answer `platform:pcspkr`; Debian 7.3.4's lists only `pcspkr`, so udev loads both here and the second registration fails. `pcspkr` stays loaded, `snd_pcsp` does not. Why the Debian alias table lacks `snd_pcsp` is untested.
- Fix: none. Candidate: `blacklist snd_pcsp` in `/etc/modprobe.d/` (untested).
- Checked: 2026-11-16, `grep pcspkr /lib/modules/*/modules.alias`; `lsmod` shows `pcspkr` only. The PC Speaker line appears on boot -1 with no error.

### F9 — systemd `bpf-restrict-fs` fails: no kernel BTF

- Status: ❌ open
- Machine / kernel: debian (Lenovo Yoga 7 14IRL8), 7.4.0-rc3 `#6-c3d1b926` against 7.3.4+deb14-amd64 `#1` (boot -1)
- Symptom: `systemd[1]: bpf-restrict-fs: Failed to load BPF object: No such process`. On boot -1 the same step logged `bpf-restrict-fs: LSM BPF program attached`.
- Cause: `~/linux/.config` has `CONFIG_DEBUG_INFO_NONE=y`, so `CONFIG_DEBUG_INFO_BTF` is off and `/sys/kernel/btf/vmlinux` does not exist; systemd's LSM program is CO-RE and needs it. Debian's config has `CONFIG_DEBUG_INFO_BTF=y`, and `bpf` is in the active LSM list on both kernels. `KERNEL-INSTALL.md` says the working config has BTF on, which is not true of this tree.
- Fix: none yet. Candidate: `scripts/config -e DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT -e DEBUG_INFO_BTF`, full rebuild (pahole v1.32 is installed) — untested.
- Checked: 2026-11-16, `ls /sys/kernel/btf/vmlinux` → no such file; `grep DEBUG_INFO ~/linux/.config`.

### F8 — `make loop` reports hashed pointers as new error lines

- Status: 🟢
- Machine / kernel: samsung13, 7.4.0-rc3-xbill `#13-83441d3f` against 7.4.0-rc2-xbill+ `#10` (boot -1)
- Symptom: `make loop` exit 1 with `+1  ACPI Error: Needed [Integer/String/Buffer], found [Reference] 000000006b05a082 (N/exresop-388)` and one more like it, while the 16 baseline copies of the same message were listed as gone
- Cause: `%p` prints a pointer hashed per boot as 16 hex digits with no `0x`; `kernel-log-compare` normalised only `0x` hex, so every copy was a distinct line
- Fix: `94316e9`, `kernel-log-compare` replaces 16-digit hex words with `P` before comparing
- Checked: 2026-11-16, `make loop` on the same two boots: no new kernel error lines, exit 0; the exresop line shows as `-16` against the baseline

### F7 — Wacom digitizer incorrect report

- Status: ❌ open, not investigated
- Machine / kernel: yoga9i; seen on 7.4.0-rc2-mainline+ `#15` (boot -1) and 7.4.0-rc3-mainline `#17-1b4c2939` (boot 0)
- Symptom: `i2c_hid_acpi i2c-WACF2200:00: device returned incorrect report (0 vs 11 expected)`, 3 times per boot
- Cause: unknown. Absent on 7.4.0-rc2-mainline `#6` (boot -2) and on boot -3, so it is not tied to rc3.
- Fix: none
- Checked: `kernel-log-compare -2` on 2026-11-16 lists it as `+3` new against `#6`; the journal count is 3 on boots 0 and -1, 0 on boots -2 and -3.

### F6 — runtime-PM udev rule logs `Could not chase`

- Status: ⚠️ committed, untested
- Machine / kernel: the machine that runs `intel/udev/99-no-runtime-pm.rules`; the rule is not installed on yoga9i
- Symptom: about 40 `Could not chase sysfs attribute` lines per boot
- Cause: the rule wrote `power/control` on USB interfaces and i2c adapters, which have no such file
- Fix: `7ed46de`, `TEST=="power/control"` on each match. Install: `sudo install -m 644 intel/udev/99-no-runtime-pm.rules /etc/udev/rules.d/`
- Checked: untested. On that machine, after a reboot, `journalctl -b | grep -c 'Could not chase'` should read 0.

### F5 — NVIDIA DKMS fails under `make install`

- Status: ⚠️ committed, untested
- Machine / kernel: `gpu` and `yogagpu` (NVIDIA DKMS); yoga9i has no DKMS modules
- Symptom: the NVIDIA DKMS build fails on an empty `src`, and run-parts stops before the initramfs and GRUB hooks
- Cause: `make install` exports `KERNELRELEASE` into the postinst.d hooks, and the dkms hook inherits it
- Fix: `1c9191f`. With any module in `dkms status`, `kernel-build` installs by hand under `env -i`: copy the image, `dkms build --force` and `dkms install --force` per module, `update-initramfs`, `update-grub`. The manual steps are in `intel/docs/KERNEL-INSTALL.md` Step 4.
- Checked: untested by `kernel-build` on an NVIDIA machine. On yoga9i the path is skipped and `make install` still runs, as on 2026-11-16 (build `#19-52838078`).

### F4 — boot checks read an older build of the same release

- Status: 🟢
- Machine / kernel: yoga9i, 7.4.0-rc2-mainline+
- Symptom: build `#15` booted at 16:49 on 2026-11-14, `#16` was installed at 17:18, and the next morning's checks read `#15`, with taint 0
- Cause: a rebuild of the same release installs over the same `/boot` and `/lib/modules` paths, and suspend and resume keeps the old kernel running
- Fix: `d045c39`. `kernel-build` stamps `KBUILD_BUILD_VERSION=<n>-<8 hex>` and records the install; `kernel-boot-check` (and `make feedback`, `make loop`) refuses every other check unless `uname -r -v` matches the record.
- Checked: 2026-11-16, `kernel-boot-check` exit 0 on `#17-1b4c2939` while it was the installed build; exit 1, `NOT THE INSTALLED BUILD`, once `#19-52838078` was installed and `#17` still running.

### F3 — new build installed but not the GRUB default

- Status: 🟢
- Machine / kernel: yoga9i
- Symptom: after `make install`, the old kernel kept booting
- Cause: `GRUB_DEFAULT` names an entry by release (`gnulinux-<release>-advanced-<uuid>`)
- Fix: `12fc365`. `kernel-build` swaps the release in that id, runs `update-grub`, and restores a dated backup if the id is missing from `grub.cfg`.
- Checked: 2026-11-16, `kernel-build` printed `GRUB_DEFAULT already boots 7.4.0-rc3-mainline` for build `#19-52838078`.

### F2 — initrd 641MB from unstripped modules

- Status: 🟢
- Machine / kernel: yoga9i, `CONFIG_DEBUG_INFO=y`
- Symptom: `/lib/modules/<rel>` 1.3G and the initrd 641MB (2026-11-14)
- Cause: a plain `modules_install` keeps full DWARF in every module
- Fix: `12fc365`, `INSTALL_MOD_STRIP=1`, which keeps the `.BTF` sections
- Checked: 2026-11-16, build `#19-52838078`: `/boot/initrd.img-7.4.0-rc3-mainline` 89,868,425 bytes, `/lib/modules/7.4.0-rc3-mainline` 118M.

### F1 — 7.4-rc2: no sound card, no microphone

- Status: 🟢 fixed upstream
- Machine / kernel: yoga9i, 7.4-rc2 built with GCC 16
- Symptom: `fail to add hda routes, ret -19`, no sound card, no DMIC
- Cause: 7.4-rc2 commit `4dd10fbbeb9c` moved the ASoC runtime allocation in `soc_new_pcm_runtime()` to `devm_kzalloc_flex()`. With GCC 16 (`__builtin_counted_by_ref`) that presets `rtd->num_components` to the capacity, so no component is probed.
- Fix: upstream `d00ba321499c` "ASoC: soc-core: reset rtd->num_components after allocation", pulled 2026-11-14. No local patch.
- Checked: 2026-11-15, `arecord -l` lists `DMIC` and `DMIC16kHz` on build `#15` (`articles/kernel-agent-loop/evidence/yoga9i-boot-check.txt`).
