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
