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
| F21 | ❌ | debian13u (Yoga 7 14IRL8) | `geoclue.service` start timed out once at boot on rc3 `#14`; a manual start succeeds | none yet |
| F20 | ❌ | samsung13 | `make loop` exit 1 on rc3 `#9`: Intel AX211 Bluetooth firmware download fails once, then the driver's retry succeeds | none yet |
| F19 | ❌ | debian (Yoga C630) | `make loop` exit 1 on rc3 `#11`: QRTR `failed to announce new service`, intermittent on every mainline 7.4 | none yet |
| F18 | 🟢 | debian (Galaxy Book Go) | new build installed with no Book Go boot entry | `82af936` |
| F17 | ❌ | debian (Yoga C630) | `make loop` exit 1 on rc3 `#10`: five "new" error lines, four of them intermittent on rc2 as well | none yet |
| F16 | ❌ | yoga9i | iwlwifi `session protection is over` on a failed roam | none yet |
| F15 | 🟢 | yoga9i | user unit `gnome-software.service` failed at every login | `intel/autostart/` override hides the autostart copy |
| F14 | ❌ | debian (Yoga 7 14IRL8) | `pam_wtmpdb` cannot write `wtmp.db` at logout | none yet |
| F13 | 🟢 | debian (Yoga C630) | `make loop` stops: no install record | see F13 |
| F12 | ❌ | debian (Yoga C630) | `Bluetooth: hci0: unexpected event for opcode 0x0000` | none yet |
| F11 | 🟢 | debian (Yoga C630) | built-in Wi-Fi appears ~95 s after boot | `34d4e11` (mask) |
| F10 | ❌ | debian (Yoga 7 14IRL8) | `Driver 'pcspkr' is already registered` at boot | none; avoided by `localmodconfig` on `#12` |
| F9 | 🟢 | debian (Yoga 7 14IRL8) | systemd `bpf-restrict-fs` cannot load: no kernel BTF | config: `DEBUG_INFO_BTF=y` |
| F8 | 🟢 | samsung13 | `make loop` reports hashed `%p` pointers as new error lines | `94316e9` |
| F7 | ❌ | yoga9i, debian13u (Yoga 7 14IRL8) | Wacom digitizer: `device returned incorrect report (0 vs 11 expected)` | none yet |
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

### F21 — debian13u `geoclue.service` start timeout on rc3 `#14`

- Status: ❌ open. Seen once. The symptom is in userspace; the cause is unknown.
- Machine / kernel: debian13u (Lenovo Yoga 7 14IRL8), 7.4.0-rc3+ `#14-24598a3e` (`v7.4-rc3-406-g65e4fd942f72`) against `#13-36eeb02e` (boot -1)
- Symptom: `make feedback` shows `systemctl is-system-running` `degraded` and `● geoclue.service loaded failed failed Location Lookup Service`; `make loop` exits 0 but lists `geoclue.service` under units that failed in this boot only. At 8.84 s the GDM gnome-shell D-Bus-activates `org.freedesktop.GeoClue2`; dbus-daemon gives up at 33.8 s (`service_start_timeout=25000ms`) and systemd kills the unit at 98.9 s (`start operation timed out`, `Result: timeout`). `/usr/libexec/geoclue` (PID 2082) used 43 ms CPU in those 90 s and never took the bus name, so it was blocked, not busy. What it was waiting on is untested.
- Cause: unknown. Whether the kernel is involved is untested; this boot has no kernel error lines (`journalctl -k -b -p err` is empty).
- Fix: none
- Checked: 2026-11-20. Across the 26 boots in the journal (from 2026-09-05), `geoclue.service` `Failed with result 'timeout'` appears only in boot 0. On `#13` (boot -1) the unit started and idled out normally (`Service not used for 60 seconds`). `sudo systemctl start geoclue.service` at 09:23:43 returned at once with `active`. Next: watch whether it recurs on the next boots of `#14`.

### F20 — samsung13 Bluetooth firmware download fails once on rc3 `#9`

- Status: ❌ open. Looks harmless: the driver's own retry loaded the firmware in the same boot. Seen once.
- Machine / kernel: samsung13, 7.4.0-rc3-xbill+ `#9-349f03e8` (`v7.4-rc3-178-g20eef29b7c84`) against 7.4.0-rc3-xbill `#7` (boot -1)
- Symptom: `kernel-log-compare` exit 1 with 2 new lines from the Intel AX211 Bluetooth controller (USB `8087:0033`, firmware `intel/ibt-0040-0041.sfi`, version 24-29.26). At 4.84 s the download starts; at 6.40 s `Failed to send firmware data (-38)` and at 6.41 s `Failed to send Intel get rom debug info command (-56)`, then `Intel reset sent to retry FW download`. The second attempt starts at 6.99 s and ends `Firmware loaded in 1463339 usecs` and `Device booted in 15607 usecs` at 8.51 s; DDC parameters and Fseq apply normally.
- Cause: unknown. The lines come from `drivers/bluetooth/btintel.c`: the `btintel_secure_send()` failure in the firmware download loop (line 1242), then `btintel_get_rom_debug_info()` (line 1000) on the error path, then the reset-and-retry at line 1492. `-38` is `ENOSYS`; where `btintel_secure_send()` gets it from is untested. No commits touch `drivers/bluetooth` or `net/bluetooth` between v7.4-rc3 and the build's commit, so a change in this build is not the likely cause (untested).
- Fix: none
- Checked: 2026-11-19. In the 22 boots in the journal (from 2026-09-04), `Failed to send firmware data` appears only in this boot; the previous two (rc3 `#7`, rc2) loaded the firmware first time. `bluetoothctl show` lists the controller (`Powered: no`; whether that is the saved user setting is untested). Next: watch whether it recurs on the next boots.

### F19 — C630 `make loop` flags two QRTR lines on rc3 `#11`

- Status: ❌ open. Looks harmless (see Checked); errno not yet measured.
- Machine / kernel: debian (Yoga C630), 7.4.0-rc3-00230-g4405c18c95d2 `#11-6d50eebf` against 7.4.0-rc3 `#10-50789359` (boot -1)
- Symptom: `kernel-log-compare` exit 1 with 2 new lines at 11:38:31.90, 0.1 ms before `remoteproc3: remote processor 4080000.remoteproc is now up` (the modem, MSS): `failed to announce new service` and `failed while handling packet from 0:-2`.
- Cause: the in-kernel QRTR name server, `net/qrtr/ns.c`. `0:-2` is node 0 (the modem; `qrtr-lookup` lists all modem services on node 0) and port `QRTR_PORT_CTRL`. The pair comes from `qrtr_ns_worker()` handling a HELLO from the modem: `ctrl_cmd_hello()` → `announce_servers()` sends `NEW_SERVER` for each local server to node 0, and the first send that fails with anything but `-ENODEV` prints line 234 and aborts the loop, then the worker prints line 693. Local servers exist by then: rmtfs (14), pd-mapper (64) and tqftp (4096) on node 1 start at 11:38:30.08–30.10. Not new in this build: it starts with upstream `544d85de4dc2` "net: qrtr: Send HELLO message on endpoint register" (in v7.3-rc2), which moved the outbound HELLO from the name server into the core and made `qrtr_node_enqueue()` return `-EAGAIN` for any non-HELLO packet until `node->hello_sent` is set. Debian 7.2.9 predates it. Likely race (untested): the modem's own HELLO reaches the name server before the core's `qrtr_hello_work()` has sent ours, so the announce gets `-EAGAIN`. `qrtr_hello_work()` then injects a HELLO to the name server once both `hello_sent` and `hello_rcvd` are set, which reruns `announce_servers()`. That would explain why it happens on some boots only. Other errnos the send can return (`-ECONNRESET` for an unknown node, `-EPIPE` from flow control) are not ruled out. No upstream fix found as of 2026-11-19 (torvalds `4405c18c95d2`, and a web search).
- Fix: none
- Checked: 2026-11-19. Counted over the 52 boots in the journal, the pair appears together in 10 of 15 mainline 7.4 boots (rc2-00696: 1 of 3, rc2-00859: 5 of 6, plain 7.4.0-rc3 builds: 2 of 5, rc3-00230: 1 of 1) and in none of the 37 Debian-kernel boots (6.12.107, 6.12.111, 7.2.9). The baseline `#10` boot happened to lack it, as in F17. The modem found the local servers anyway in this boot: rmtfs got requests at 11:38:31.94, tqftpserv at 11:38:32.14, ModemManager probed `qrtr0` at 11:38:33, and Wi-Fi (ath10k, a modem QMI client) came up at 11:38:32. Next: a `kretprobe` on `qrtr:service_announce_new` (in `/proc/kallsyms`, not inlined) armed before `rmtfs.service` on the next boot, to record the return value.

### F18 — new build installed with no Galaxy Book Go boot entry

- Status: 🟢 fixed
- Machine / kernel: debian (Galaxy Book Go), `7.4.0-rc3-00230-g4405c18c95d2-dirty`, build `6-ed80d002`
- Symptom: after `make install` (2026-11-19) `grub.cfg` had only the generic `10_linux` entries for the new build, which load no device tree. No `gbgo-<rel>` entry.
- Cause: the kernel's install hook runs `update-grub` while the image is still `/boot/vmlinux-<rel>`. `kernel-build` copies it to `/boot/vmlinuz-<rel>` afterwards, and `09_galaxy-book-go` lists `/boot/vmlinuz-*`.
- Fix: `82af936`, `kernel-build` runs `update-grub` again after the copy on arm64 machines without `c630-menu`. The default entry is not changed.
- Checked: 2026-11-19, a manual `sudo update-grub` printed `Found Galaxy Book Go entry: 7.4.0-rc3-00230-g4405c18c95d2-dirty`, `grub.cfg` has `gbgo-7.4.0-rc3-00230-g4405c18c95d2-dirty` with the DTB, and `gbgo-boot-verify` exited 0. Build `7-de0ed44e` (`7.4.0-rc3-00395-g8dac6df92a2e-dirty`), installed the same day with the fix, got `gbgo-7.4.0-rc3-00395-g8dac6df92a2e-dirty` in `grub.cfg` with no manual step. Booting that entry is untested.

### F17 — C630 `make loop` flags five error lines on rc3 `#10`

- Status: ❌ open. No new oops or warning, no failed unit.
- Machine / kernel: debian (Yoga C630), 7.4.0-rc3 `#10-50789359` against 7.4.0-rc2-00859 `#5` (boot -1, a 9-minute boot)
- Symptom: `kernel-log-compare` exit 1 with 5 new lines: `dwc3 a800000.usb: Failed to create device link ... hub@2`, `qcom-soundwire ... SWR CMD error ... flushing fifo`, `wcd934x-codec ... Port Closed RX port 0` and `port 1`, and `ti_sn65dsi86 10-002c: Failed to create device link (0x180) with supplier backlight`.
- Cause: four of the five are not new in rc3. Counted over the last 12 boots, the `dwc3` line is in 3 of 6 rc2 boots and 4 of 5 rc3 boots, `SWR CMD error` in 2 of 6 and 3 of 5, and `Port Closed RX` in every boot but the baseline. The baseline was short and happened to have none. The `ti_sn65dsi86` line is the only one seen once in the 52 boots in the journal; it follows two `Fixed dependency cycle(s)` lines between `/backlight` and the panel. Cause not looked into. The compare takes one boot as the baseline, so lines that come and go count as new.
- Fix: none
- Checked: 2026-11-19, this boot: backlight device present (`brightness` 3063 of 4095), panel on, 3 sound cards listed by `aplay -l`. Sound output not listened to. Not checked whether the `ti_sn65dsi86` line repeats.

### F16 — iwlwifi `session protection is over` when a roam fails

- Status: ❌ open, not investigated past the journal
- Machine / kernel: yoga9i (Intel Wi-Fi at `0000:00:14.3`), 7.4.0-rc3 `#19-52838078` (boot 0, 2 lines); also 7.4.0-rc2 (boot -2, 3 lines on 2026-11-15); absent on boots -1, -3, -4
- Symptom: `iwlwifi 0000:00:14.3: Not associated and the session protection is over already...`, once per auth retry, each followed by `wlp0s20f3: Connection to AP …:80 lost`.
- Cause: unknown. Sequence in boot 0, 2026-11-17 12:30:58–12:31:09: the AP sends a WNM preferred-candidate list, the client leaves the `…:88` BSSID to authenticate with `…:80` (SAE), the kernel logs `unexpected authentication state: alg 3 (expected 3) transact 1 (expected 2)` 7 times, auth tries 2 and 3 time out with the iwlwifi line, the supplicant aborts and ignores `…:80`, and the client connects to `…:84` at 12:31:09. Wi-Fi drops for about 9 s. The AP side of the SAE exchange is a candidate (untested).
- Fix: none
- Checked: `journalctl -k -b N | grep -c "session protection is over"` on 2026-11-17: boot 0 → 2, -1 → 0, -2 → 3, -3 → 0, -4 → 0.

### F15 — `gnome-software.service` fails at every login

- Status: 🟢 fixed, checked on yoga9i across a reboot and login
- Machine / kernel: yoga9i, 7.4.0-rc3 `#19-52838078` (boot 0); also boots -1 to -3, `#17-1b4c2939` among them
- Symptom: `make feedback` lists `● gnome-software.service loaded failed failed GNOME Software` under `systemctl --user --failed`. Journal: `gnome-software[4191]: Unable to acquire bus name 'org.gnome.Software'`, three restarts, then `Failed with result 'start-limit-hit'`.
- Cause: two copies start at login. `/etc/xdg/autostart/org.gnome.Software.desktop` launches `gnome-software --gapplication-service` (PID 3941, scope `app-gnome-org.gnome.Software-3941.scope`), which takes the bus name; the systemd user unit (`Type=dbus`, `BusName=org.gnome.Software`) then cannot take it. Userspace only; `make loop` does not see it, since it counts system units.
- Fix: `intel/autostart/org.gnome.Software.desktop` (`Hidden=true`) overrides the autostart entry for the user, so only the systemd unit starts it, which is the path D-Bus activation already uses (`SystemdService=gnome-software.service`). Install: `install -Dm644 intel/autostart/org.gnome.Software.desktop ~/.config/autostart/org.gnome.Software.desktop`
- Checked: `journalctl --user -b N | grep -c "start-limit-hit"` on 2026-11-17: 1 on each of boots 0, -1, -2, -3; `busctl --user status org.gnome.Software` shows PID 3941 owns the name and gnome-software is running. After the fix, 2026-11-17: `desktop-file-validate` exit 0; with the autostart copy stopped, `systemctl --user start gnome-software.service` gives `active`, and `busctl --user status org.gnome.Software` shows `UserUnit=gnome-software.service`. After a reboot into 7.4.0-rc3 `#20-4e83ed55` and a fresh login, 2026-11-17 15:31: `systemctl --user --failed` is empty; `journalctl --user -b` has one `Started gnome-software.service`, no `Unable to acquire bus name`, no `start-limit-hit` and no `app-gnome-org.gnome.Software-*.scope`; `busctl --user status org.gnome.Software` shows `UserUnit=gnome-software.service` (PID 4179).
- Also on debian13u (Yoga 7 14IRL8), 7.4.0-rc3+ `#14-24598a3e`, 2026-11-20: the same `start-limit-hit`, and `journalctl --user -b` has 3 `Unable to acquire bus name 'org.gnome.Software'` lines. The override is not installed there (`~/.config/autostart/org.gnome.Software.desktop` is missing). Not yet applied; whether it fixes debian13u is untested.

### F14 — `pam_wtmpdb` cannot write `wtmp.db` at logout

- Status: ❌ open, not investigated
- Machine / kernel: debian (Lenovo Yoga 7 14IRL8), 7.4.0-rc3 `#7-1a43c85b` (boot 0); absent on `#6-c3d1b926` (boot -1) and 7.3.4+deb14-amd64 (boot -2)
- Symptom: `(sd-pam)[7727]: pam_wtmpdb(login:session): Updating logout time failed: attempt to write a readonly database`, 8 times at 09:03:27, one per `sd-pam` process. In the same boot `gkr-pam: couldn't unlock the login keyring` rose from 2 to 10.
- Cause: unknown. `make loop` does not flag it, since it is not a kernel line; it shows as +12 in "all errors, whole journal". `/var/lib/wtmpdb/wtmp.db` links to `/var/log/wtmp.db`. The only change from `#6` is BTF (F9), which lets systemd's `bpf-restrict-fs` LSM enforce `RestrictFileSystems=` for the first time on a mainline build, so that is a candidate (untested).
- Fix: none
- Checked: `journalctl -b -N | grep -c pam_wtmpdb` on 2026-11-17: 8 on boot 0, 0 on boots -1 and -2.

### F13 — `make loop` stops on the C630: no install record

- Status: 🟢 fixed, checked on the C630 across a reboot into `#11`
- Machine / kernel: debian (Yoga C630), 7.4.0-rc3 `#9`
- Symptom: `no install record at ~/.local/state/kernel-build/installed; install with kernel-build first`, then `make: *** [Makefile:46: loop] Error 2`
- Cause: on the C630, `~/bin/kernel-build` was a stale local copy (1732 bytes, 2026-11-14) from before build IDs, not the repo symlink. It wrote no install record. The repo script would also have failed here: its `/boot` check uses `file(1)`, which reads the version only from an x86 bzImage, and on arm64 `make install` leaves only `/boot/vmlinux-<rel>`, with no `vmlinuz` or DTB, so `c630-menu` skips the kernel.
- Fix: `intel/scripts/kernel-build` on arm64 copies `arch/arm64/boot/Image` to `/boot/vmlinuz-<rel>`, runs `dtbs_install` into `/usr/lib/linux-image-<rel>/`, reruns `c630-menu` and `grub-script-check` and confirms the `c630-<rel>` entry, then checks the build ID with `grep -a` in the Image. It skips `set_grub_default`; the C630 default stays pinned in `/etc/default/c630-menu`. `~/bin/kernel-build`, `kernel-boot-check` and `kernel-log-compare` are now repo symlinks (old copy at `~/bin/kernel-build.pre-repo-link`). x86 path unchanged.
- Checked: 2026-11-19, boot of `#11-6d50eebf` (installed by the repo `kernel-build`): `kernel-boot-check` exit 0 with the build ID matched, and `make loop` ran the build ID check and `kernel-log-compare` through (exit 1 is F19, not this). Earlier, 2026-11-16, `make install NOPULL=1`: build `#10-50789359`, install record written, `c630.cfg has c630-7.4.0-rc3`, default still rc2. With `INSTALL_MOD_STRIP=1` now applied, the initrd is 29 MB (was 54.6 MB) with the same 10 firmware files and 795 modules as rc2's; `/lib/modules/7.4.0-rc3` is 97M.

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
- Update 2026-11-19: gone on debian13u `#12-32f07622` only because `localmodconfig` no longer builds `snd_pcsp` ([YOGA7-TUNING.md](intel/docs/YOGA7-TUNING.md)); the clash is still there in any config that builds both. `make loop` against `#10` lists it as `-1`.

### F9 — systemd `bpf-restrict-fs` fails: no kernel BTF

- Status: 🟢
- Machine / kernel: debian (Lenovo Yoga 7 14IRL8), 7.4.0-rc3 `#6-c3d1b926` against 7.3.4+deb14-amd64 `#1` (boot -1)
- Symptom: `systemd[1]: bpf-restrict-fs: Failed to load BPF object: No such process`. On 7.3.4 the same step logged `bpf-restrict-fs: LSM BPF program attached`.
- Cause: `~/linux/.config` had `CONFIG_DEBUG_INFO_NONE=y`, so `CONFIG_DEBUG_INFO_BTF` was off and `/sys/kernel/btf/vmlinux` did not exist; systemd's LSM program is CO-RE and needs it. Debian's config has `CONFIG_DEBUG_INFO_BTF=y`, and `bpf` is in the active LSM list on both kernels.
- Fix: config change, not a commit: `scripts/config -d DEBUG_INFO_NONE -e DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT -e DEBUG_INFO_BTF -e DEBUG_INFO_BTF_MODULES`, then a full `NOPULL=1 make install` (2042 s on this machine). Stripped modules 118M, initrd 206M (201M before).
- Checked: 2026-11-17 on `#7-1a43c85b`: `make feedback` exit 0; `/sys/kernel/btf/vmlinux` present; journal reads `bpf-restrict-fs: LSM BPF program attached`; `make loop` against `#6-c3d1b926` lists the error as `-1`, exit 0.

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
- Also on debian13u (Lenovo Yoga 7 14IRL8; was hostname `debian` in F9–F10, F14): `i2c_hid_acpi i2c-WACF22005362:00: device returned incorrect report (0 vs 11 expected)`, 3 times on 7.4.0-rc3+ `#10-12f8f214` (`v7.4-rc3-230-g4405c18c95d2`, boot 0, 2026-11-19). Count is 0 on the six boots before it: `#9-80b0b4f4`, `#7-1a43c85b`, `#6-c3d1b926`, Debian 7.3.4 `#1`, 7.4.0-rc2+ `#3` and `#2`. One boot is not enough to tie it to the commits between `#9` and `#10`; whether it repeats on the next boot of `#10` is untested. Absent on the next boot, `#12-32f07622` (same source, tuned config), 2026-11-19.
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
