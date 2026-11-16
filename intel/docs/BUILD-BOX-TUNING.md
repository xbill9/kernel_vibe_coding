#### Tuning the `build` box for throughput

`build` is an Intel Core i7-3770 (Ivy Bridge, 4 cores / 8 threads, 3.4–3.9 GHz) with 31 GiB RAM and two Samsung SSD 840 drives on SATA, running mainline (7.4.0-rc3-mainline). It is a build machine, so the kernel is tuned for throughput over hardening and desktop latency.

---

#### The settings

All four are boot options, installed as a GRUB drop-in from [`intel/grub/90-build-perf.cfg`](../grub/90-build-perf.cfg):

```
sudo install -m644 intel/grub/90-build-perf.cfg /etc/default/grub.d/ && sudo update-grub
```

| Option | Default it replaces | Why |
|---|---|---|
| `mitigations=off` | Meltdown PTI, Spectre v2 retpolines, MDS buffer clearing, L1TF | On Ivy Bridge these make every system call expensive; builds make millions of them |
| `init_on_alloc=0` | `CONFIG_INIT_ON_ALLOC_DEFAULT_ON=y`: every allocation zeroed | Hardening cost on every allocation |
| `preempt=voluntary` | `full (lazy)` | Favours throughput over desktop responsiveness |
| `cpufreq.default_governor=performance` | `schedutil` on `intel_cpufreq` | Holds the top clock instead of ramping for short build steps |

⚠️ `mitigations=off` removes protection against Spectre, Meltdown and MDS. Keep it only while the machine runs no untrusted code: no browser, no untrusted VMs or containers, no other users.

To undo: `sudo rm /etc/default/grub.d/90-build-perf.cfg && sudo update-grub`, then reboot.

---

#### Already right, left alone

- Kernel built with `CONFIG_X86_NATIVE_CPU=y` and `CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE=y`.
- `mq-deadline` on both SSDs; `fstrim.timer` enabled.
- Swap unused with 29 GiB free, so no swap or zswap tuning.
- Microcode `0x21` loaded, `intel-microcode` 3.20261110.1 installed. SRBDS still reports `Vulnerable: No microcode`.
- Not changed: `CONFIG_UBSAN` (bounds and shift checks) is built in; removing it needs a rebuild. Untested.

---

#### Measuring

[`intel/bench/build-box-bench`](../bench/build-box-bench) prints the kernel, command line and governor, times 5 million empty system calls three times ([`getppid-bench.c`](../bench/getppid-bench.c)), then times three clean `tinyconfig` builds (`make -j8`) of `~/linux` HEAD exported to a temp directory.

| | Command line | `getppid` (ns/call) | `tinyconfig` build (s) |
|---|---|---|---|
| Before, 2026-11-16 | `ro quiet` | 318.2, 317.2, 318.1, 323.1, 320.6, 324.7 | 45.84, 46.16, 46.88 |
| After | `ro quiet mitigations=off init_on_alloc=0 preempt=voluntary cpufreq.default_governor=performance` | untested: needs a reboot | untested: needs a reboot |

Source for both: `aebb72744764 Linux 7.4-rc3`.
