#### Tuning the Yoga 7 14IRL8 (`debian13u`) kernel

`debian13u` is a Lenovo Yoga 7 14IRL8: Intel Core i5-1335U (Raptor Lake, 2 P-cores + 8 E-cores, 12 threads), NVMe root on ext4, i915 graphics, SOF audio, a Wacom pen digitizer. It is a laptop that runs a desktop and a browser. Its kernel is built from `~/linux` with Spectre mitigations compiled out, `-march=native`, and only the modules this machine uses. Everything here was done on 2026-11-19 on build `#12-32f07622` (`v7.4-rc3-230-g4405c18c95d2`).

⚠️ This kernel has no Spectre v2, speculative store bypass or register-file-sampling protection, and it runs a browser. Untrusted code (JavaScript, other users, untrusted containers or VMs) can in principle read other processes' or the kernel's memory. That is an accepted risk on this machine, not a recommendation.

---

#### Config changes

Applied with `scripts/config` on top of the BTF config from F9 in [FIXES.md](../../FIXES.md), then `make olddefconfig`:

```sh
cd ~/linux
scripts/config -d CPU_MITIGATIONS -e X86_NATIVE_CPU -d INIT_ON_ALLOC_DEFAULT_ON -d UBSAN
make olddefconfig
```

| Option | Was | Now | Why |
|---|---|---|---|
| `CONFIG_CPU_MITIGATIONS` | `y` (23 `CONFIG_MITIGATION_*` options on) | off (all 23 off) | Compiles out retpolines, return thunks, IBRS/IBPB entry, BHI clearing, call-depth tracking and the rest |
| `CONFIG_X86_NATIVE_CPU` | off | `y` | `-march=native` for the i5-1335U; this kernel will not run on another CPU |
| `CONFIG_INIT_ON_ALLOC_DEFAULT_ON` | `y` | off | No zeroing of every page and slab allocation |
| `CONFIG_UBSAN` | `y` | off | No runtime bounds and shift checks |

`CONFIG_DEBUG_INFO_BTF=y` stays on: systemd's `bpf-restrict-fs` needs it (F9).

Backups: `~/linux/.config.pre-perf` is the config before any of this, `~/linux/.config.pre-localmod` has the four changes above but the full module set.

---

#### Only this machine's modules (`localmodconfig`)

```sh
cd ~/linux
make LSMOD=$HOME/kernel_vibe_coding/intel/config/yoga7-14irl8.lsmod localmodconfig
```

[`intel/config/yoga7-14irl8.lsmod`](../config/yoga7-14irl8.lsmod) is `lsmod` from build `#10` (251 modules, including USB storage, KVM, bridge/nf_tables/overlay for containers, `uvcvideo`, `btusb`, `wacom`) plus 19 that were not loaded but are likely to be needed on hot-plug, each added as `<name> 0 0`:

- filesystems and block: `exfat`, `isofs`, `udf`, `loop`, `dm_crypt`, `nls_iso8859_1`, `nls_utf8`
- USB audio and network: `snd_usb_audio`, `cdc_ether`, `cdc_ncm`, `rndis_host`, `r8152`, `ax88179_178a`
- containers and VPN: `veth`, `br_netfilter`, `nft_masq`, `tun`, `wireguard`
- `uinput`

`ntfs3` was not built in the old config either; `fuse` is built in.

`=m` options went from 4030 to 324; 330 `.ko` files are installed.

What is gone: any driver for hardware that was neither plugged in nor on the list above, including other USB network and serial adapters, printers that need a kernel module, and `snd_pcsp` and `lenovo_wmi_gamezone` (neither was loaded; see below).

##### Adding a module later

A module that was cut was never compiled, so `modprobe` cannot find it (`modinfo <name>` says `not found`). Build just that module from the same tree, untested:

```sh
cd ~/linux
grep <OPTION> .config.pre-localmod            # find the option name
scripts/config -m <OPTION> && make olddefconfig
make -j$(nproc) modules
sudo make INSTALL_MOD_STRIP=1 modules_install  # runs depmod
sudo modprobe <module>
```

This works without a reboot because `CONFIG_MODVERSIONS` is off and the signing key in `~/linux/certs/` is the one the running kernel trusts. Two conditions:

- `olddefconfig` must not turn on anything `=y`. `CONFIG_MODULE_ALLOW_BTF_MISMATCH` is off, so a module built against a changed `vmlinux` is refused at load. If anything built-in changes, run `NOPULL=1 make install` and reboot.
- The tree must still be at the installed commit. Do not `git pull` first.

To keep it in future builds, add `<name> 0 0` to the `.lsmod` file.

---

#### Left alone

- `preempt` stays `full (lazy)`. `preempt=voluntary`, used on the `build` box ([BUILD-BOX-TUNING.md](BUILD-BOX-TUNING.md)), trades desktop latency for throughput.
- `intel_pstate` in active mode with `powersave`. With hardware P-states the CPU still picks its own frequency; `performance` mostly costs battery and heat. `cpufreq.default_governor=` does not apply to `intel_pstate` active mode.
- No GRUB drop-in. Everything is compiled in, so the Debian fallback kernel keeps its mitigations.

---

#### Results

| | `#10-12f8f214` | `#12-32f07622` |
|---|---|---|
| Config | Debian-derived, BTF on, mitigations on, all modules | as above |
| `getppid` (ns/call, 5 runs) | 64.3, 63.7, 63.2, 63.3, 63.2 | 57.5, 57.6, 57.4, 57.2, 57.2 |
| `/boot/initrd.img` | 206M (`#7`) | 49M |
| `/lib/modules/<rel>` (stripped) | 118M (`#7`) | 16M |
| `/boot/vmlinuz` | 15M (`#7`) | 12M |
| Full build | 2042 s (`#7`, rc3) | 549 s |

Both `getppid` runs were on mains power with the `powersave` governor, using [`getppid-bench.c`](../bench/getppid-bench.c) compiled with `gcc -O2`. Sizes and build time for "before" are from `#7-1a43c85b` (`v7.4-rc3`, same config as `#10` apart from the source), the last full build with every module; both build times are clean rebuilds with `-j12`.

- 🟢 An empty system call dropped from 63.5 ns to 57.4 ns on average, 9.6% faster; the ranges do not overlap. The `build` box gained 5.6x from `mitigations=off` because Ivy Bridge needs PTI; this CPU is not affected by Meltdown, MDS or L1TF and handles Spectre v2 largely in hardware (eIBRS), so there was less to remove.
- 🟢 The initrd is a quarter of its size and a full build takes 3.7x less time.
- Application and boot-time gains are untested.

After the reboot, `/sys/devices/system/cpu/vulnerabilities/` reads `Vulnerable` for `spectre_v2`, `spec_store_bypass`, `reg_file_data_sampling` and `vmscape`. `spectre_v1` reads `Vulnerable: __user pointer sanitization and usercopy barriers only; no swapgs barriers`: the usercopy hardening is always built in.

`make feedback` exit 0, no kernel error lines; `make loop` against `#10`: exit 0, kernel errors 6 → 0, warnings and above 22 → 13. Of the lines gone, `pcspkr` already registered (F10) and the `lenovo_wmi_gamezone` `platform_profile probe failed` went because their modules are no longer built; the Wacom `incorrect report` (F7) comes and goes between boots, so its absence on one boot proves nothing.

---

#### Undo

```sh
cd ~/linux && cp .config.pre-perf .config && cd ~/kernel_vibe_coding && NOPULL=1 make install
```

then reboot. Use `.config.pre-localmod` instead to keep the four config changes and get every module back.
