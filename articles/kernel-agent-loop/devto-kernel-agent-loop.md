---
title: "The Vibe Coding Kernel-pocalypse Is Here, and It Is a Good Thing"
published: false
series: Linux
description: "A step by step guide to mainline Linux kernel development with a coding agent in a closed loop: the kernel's own AGENTS.md, a few markdown runbooks, a build and install script, and the boot and system logs fed back to the agent after every change. The same loop runs on an Intel laptop, two Windows-on-ARM laptops and a Pixel 3a."
tags: linux, kernel, ai, claude
cover_image: https://raw.githubusercontent.com/xbill9/kernel_vibe_coding/main/articles/kernel-agent-loop/devto-cover.313239af.jpg
---

This article provides a step by step guide to Linux kernel development with a coding agent working in a closed loop. Mainline's own `AGENTS.md`, a few markdown runbooks, one build and install script and the machine's boot logs give the agent everything it needs to change a kernel, run it and check the result.

https://github.com/xbill9/kernel_vibe_coding

**Agents write kernel code now, and the kernel community has written down how they should do it. With the loop in place, the agent builds, installs, boots and reads its own logs, and one person with a laptop does work that used to need a kernel developer at each step.**

---

#### What Is the Kernel-pocalypse?

Coding agents are in the kernel tree. Mainline has three documents written for them, all from the last year:

| Commit | Release | What it added |
| :--- | :--- | :--- |
| `78d979db6cef` | v7.0-rc1 | `Documentation/process/coding-assistants.rst`, "per the consensus reached at the 2025 Maintainers Summit" |
| `a66437c27979` | v7.0-rc1 | `Documentation/process/generated-content.rst`, guidelines for tool-generated content |
| `90d9f76ccb72` | v7.4-rc1 | `AGENTS.md`, a symlink to `README` |

That is the kernel-pocalypse: a project that runs on email and Signed-off-by lines has a file in its root addressed to language models. The documents treat agents as contributors with rules, and the rules make the agent useful.

---

#### What Is the Agent Loop?

The loop is the agent's work cycle. Each pass starts from written instructions and ends with evidence from a running kernel:

```
  ┌───────────────────────────────────────────────────────────┐
  │                                                           │
  ▼                                                           │
 read the scaffolding   AGENTS.md, CLAUDE.md, runbooks, memory  │
  │                                                           │
  ▼                                                           │
 change the tree        a fix, a config option, a device tree   │
  │                                                           │
  ▼                                                           │
 build                  kernel-build: olddefconfig, make -j     │
  │                                                           │
  ▼                                                           │
 install                stripped modules, initramfs, GRUB       │
  │                                                           │
  ▼                                                           │
 boot                   default entry, or a one-time entry      │
  │                                                           │
  ▼                                                           │
 read the logs          dmesg, journalctl, taint, failed units  │
  │                                                           │
  ▼                                                           │
 write down the result  memory file or runbook, then commit  ───┘
```

The last step is what closes the loop. A finding that is written into a file the agent loads becomes an instruction on the next pass, so the same mistake is made once.

---

#### At This Point You Should Have…

- A Linux machine you can reboot, with GRUB and a serial or SSH way back in if a kernel fails.
- A mainline clone in `~/linux`.
- A coding agent that loads `AGENTS.md` and `CLAUDE.md` and can run shell commands. This article uses Claude Code 2.1.325.
- `sudo` for the agent's install steps, approved command by command.

The Intel machine in this article is a Lenovo Yoga 9i (`Yoga 9 14IRP8`, 13th Gen Intel Core i7-1360P, 16 threads) running Debian with GCC 16.2.0.

---

#### Step 1 — Read the Kernel's Own Scaffolding

Mainline's root has an `AGENTS.md`, the file most coding agents load from a repository root on their own:

```
$ ls -l AGENTS.md
lrwxrwxrwx 1 xbill xbill 6 Nov  5 08:55 AGENTS.md -> README
```

It is a symlink to `README`, whose "AI Coding Assistant" section says an agent "MUST read and follow" `Documentation/process/coding-assistants.rst`. The commit that added the symlink gives the reason: agents often skip `README`, and an agent asked to commit a Makefile change without `AGENTS.md` "added a Signed-off-by for the user on its own".

`coding-assistants.rst` is 77 lines. The rules that shape the loop:

- **Agents must not add `Signed-off-by`.** Only a human can certify the Developer Certificate of Origin, after reviewing the change.
- **Reproduce before fixing.** A bug that is not trivial needs a reproducer, or it stops there.
- **Build and verify.** The fix must not add build warnings and must pass `checkpatch.pl`.
- **Say what was not done.** If the fix was not built or tested, the report says so.
- **The agent never sends anything itself.** The human reviews and submits.

These rules describe a loop. Build, verify, and report what could not be verified are the steps below.

---

#### Step 2 — Add Your Own Scaffolding

The kernel's documents cover the process. Your machines need their own rules, and they go in markdown files the agent loads in layers:

| File | Scope | Example rule |
| :--- | :--- | :--- |
| `~/.claude/CLAUDE.md` | every project | every figure comes from a command run in this session, or is marked untested |
| `~/linux/AGENTS.md` | the kernel tree | read `coding-assistants.rst` first |
| `CLAUDE.md` in the repo | all kernel work | follow `intel/docs/KERNEL-INSTALL.md` for installs |
| `arm/CLAUDE.md` | the ARM laptops | "Don't break the boot": one-time boots only, reboot only after the user confirms |
| agent memory | one machine | strip modules on install, or the initrd reaches 641MB |

The ARM rules are the strictest because a bad boot on those laptops costs a rescue stick. The first one reads:

```
## Don't break the boot

- **Never unhold `grub*`/`shim*`** (`apt-mark hold`). GRUB 2.14 from sid blacks out every kernel. Only GRUB 2.12 from the stick works.
```

The memory layer is written by the agent. Each file holds one fact, why it matters and how to apply it, and an index loads with every session:

```
- [Kernel install sets GRUB default](kernel-install-set-default.md) — new build becomes the boot default
- [Kernel install + NVIDIA DKMS](kernel-install-nvidia-dkms.md) — `make install` breaks DKMS; manual clean-env steps; `dkms build --force` before reinstall
- [7.4 ASoC rtd flex fix](kernel-7.4-soc-rtd-flex-fix.md) — no-mic fix now upstream (d00ba321499c); local edit dropped
- [Strip modules on kernel install](kernel-install-strip-modules.md) — use INSTALL_MOD_STRIP=1 -j$(nproc) or initrd hits 640MB
```

---

#### 🔎 Tip: Promote a Memory Into the Repo

A memory file lives on one machine. Once a fact holds on a second machine, copy it into the repo's runbook, where every machine and every reader gets it. `intel/docs/KERNEL-INSTALL.md` is four memory files rewritten as one install guide.

---

#### Step 3 — Build

`intel/scripts/kernel-build` pulls the tree, starts from the running kernel's config on a fresh clone, and builds with every core:

```
$ kernel-build --no-install
```

It prints the tree it builds from, `git describe --tags`, which on the Yoga 9i is now:

```
$ git -C ~/linux describe --tags
v7.4-rc2-716-g23c62304dde2
```

On a fresh tree it copies `/boot/config-$(uname -r)`, blanks Debian's signing keys and sets `LOCALVERSION=-mainline`. The working config has `CONFIG_RUST=y` and `CONFIG_DEBUG_INFO_BTF=y`. A full Debian package build of 7.4-rc1 on the Yoga 9i took 34 minutes 28 seconds of wall time.

---

#### Step 4 — Install

The install step is where most of the runbook's rules live, because a kernel that builds can still fail to boot or bloat the boot partition.

**Strip the modules.** With debug info on, a plain `modules_install` put full DWARF in every module: `/lib/modules/<release>` was 1.3G and the initrd 641MB, measured 2026-11-14. With `INSTALL_MOD_STRIP=1` the BTF sections stay and the size drops:

```
$ ls -l /boot/initrd.img-7.4.0-rc2-mainline+
-rw-r--r-- 1 root root 88367505 Nov 15 09:12 /boot/initrd.img-7.4.0-rc2-mainline+
$ du -sh /lib/modules/7.4.0-rc2-mainline+
118M	/lib/modules/7.4.0-rc2-mainline+
```

**Make the new build the default.** `GRUB_DEFAULT` on this laptop names an entry by release, so `make install` alone leaves the old kernel booting:

```
$ grep ^GRUB_DEFAULT= /etc/default/grub
GRUB_DEFAULT="gnulinux-advanced-c4ade253-cb80-4f6c-a4b2-0a25e3581117>gnulinux-7.4.0-rc2-mainline+-advanced-c4ade253-cb80-4f6c-a4b2-0a25e3581117"
```

`kernel-build` swaps the release in that id, runs `update-grub`, and restores a dated backup if the new id is missing from `grub.cfg`. A numeric or `saved` default is left alone. Jobs default to `nproc`, so the same script fits a 16-thread laptop and a 12-thread desktop.

**NVIDIA machines install by hand.** `make install` exports `KERNELRELEASE`, the DKMS hook inherits it, and the NVIDIA build fails on an empty `src`. The runbook's Step 4 runs `dkms`, `update-initramfs` and `update-grub` in a clean `env -i` instead.

---

#### Step 5 — Boot and Feed the Logs Back

After the reboot the agent gets one prompt: "check boot kernel and system logs for any issues". It reads the kernel version, the taint flags, the error log, kernel warnings and failed units, then sorts what it found:

```
$ uname -r -v
7.4.0-rc2-mainline+ #15 SMP PREEMPT_DYNAMIC Sat Nov 14 15:54:28 EST 2026
$ cat /proc/sys/kernel/tainted
0
$ journalctl -k -b -p err --no-pager | wc -l
62
$ journalctl -k -b -p err --no-pager | grep -c "ACPI.*AE_ALREADY_EXISTS"
58
$ journalctl -k -b --no-pager | grep -cE "Oops|BUG:|WARNING:|Call Trace|soft lockup|rcu.*stall|hung task"
0
$ journalctl -b --no-pager | grep -E "PM: suspend (entry|exit)"
Nov 14 18:13:52 yoga9i kernel: PM: suspend entry (s2idle)
Nov 15 09:10:41 yoga9i kernel: PM: suspend exit
$ arecord -l | grep DMIC
card 0: sofhdadsp [sof-hda-dsp], device 6: DMIC (*) []
card 0: sofhdadsp [sof-hda-dsp], device 7: DMIC16kHz (*) []
```

Of 62 kernel error lines, 58 are the BIOS defining the same USB port objects twice. The rest are a Wacom digitizer quirk at start-up and a PC speaker driver registered twice. No oops, no warnings, a clean suspend and resume, and both microphones present. The agent's report put each line in one of three groups: a real problem, harmless firmware noise, or userspace.

The counts come from `grep -c` and `wc -l`. The agent reads the totals the shell computed, which keeps a long log from turning into a miscount.

---

#### Step 6 — When the Logs Show a Real Bug

The microphone check above has a history. 7.4-rc2 brought commit `4dd10fbbeb9c`, a tree-wide conversion of the `devm_kmalloc()` family to typed allocators. With GCC 16 and `__builtin_counted_by_ref()`, the new `devm_kzalloc_flex()` in `soc_new_pcm_runtime()` presets `rtd->num_components` to the capacity. The sound card then starts no components, and the log shows:

```
fail to add hda routes, ret -19
```

The loop ran on that log line. The agent traced it to the allocation, added `rtd->num_components = 0;` after it, rebuilt only `snd-soc-core.ko`, reloaded the sound modules, and checked the card, both DMIC devices and a live mic signal, all on 2026-11-13. It wrote the fix and its evidence into a memory file.

Mainline already had the same line on its way. `d00ba321499c`, "ASoC: soc-core: reset rtd->num_components after allocation", was written on 2026-11-09 and arrived with the next `git pull`, on 2026-11-14:

```
+	/*
+	 * devm_kzalloc_flex() presets the __counted_by() counter to the
+	 * allocated size when the compiler has __builtin_counted_by_ref(),
+	 * but snd_soc_rtd_add_component() expects it to start from zero.
+	 */
+	rtd->num_components = 0;
```

The local edit was dropped on `git pull`, and the memory file was updated to say any tree containing `d00ba321499c` needs no patch. Upstream's commit came from a Colibri iMX7D board with a different codec: the same bug, found and fixed independently on a second machine.

---

#### Step 7 — Write Down What Was Learned

Every pass ends with a file change. The four kernel memory files on the Yoga 9i each record a date, a measurement and a "How to apply" line:

| Memory | What it changed in the loop |
| :--- | :--- |
| `kernel-install-strip-modules` | installs use `INSTALL_MOD_STRIP=1` |
| `kernel-install-set-default` | the new build becomes the GRUB default without asking |
| `kernel-install-nvidia-dkms` | NVIDIA machines install in a clean `env -i` |
| `kernel-7.4-soc-rtd-flex-fix` | the local ASoC patch is dropped once upstream has it |

The first two are now code in `kernel-build`. A rule that lives in a script runs every time, on every machine, whether or not the agent reads the note.

---

#### Step 8 — The Same Loop on ARM and Android

The repo carries the loop to three more machines, where the feedback is harder to get.

| Machine | Kernel work | Where the loop's rules live |
| :--- | :--- | :--- |
| Lenovo Yoga C630 (Snapdragon 850) | boot menu generator, firmware rollback, DTB | `arm/c630/`, `RECOVERY.md`, `QUIRKS.md` |
| Samsung Galaxy Book Go (Snapdragon 7c Gen 2) | device tree patches, boot verification, charger relay | `arm/galaxy-book-go/`, `gbgo-boot-verify` |
| Google Pixel 3a (msm-4.9) | eBPF backport: a 441-commit series, then a 1642-commit series | `android/backport-tools/`, `missing_fixes.py` |

On the ARM laptops the kernel knows only what the device tree tells it, so each guess is a reboot. The loop changes in two places. Every risky boot is a one-time entry, so a black screen falls back on the next power cycle, and `gbgo-boot-verify` checks every file the boot reads before the reboot. The bring-up of each laptop is in its own article, linked below.

On the Pixel the feedback comes from upstream instead of `dmesg`. `missing_fixes.py` finds later upstream fixes for the backported code, and `verifier-fixes.tsv` records what was done with each one.

---

#### 🔎 Tip: Make Every Risky Boot a One-Time Boot

`grub-reboot <entry>` boots an entry once and returns to the default after. The agent can try a new kernel, a new device tree or new kernel options, and a hang costs one power cycle. Combine it with the "reboot only after the user confirms" rule, and the human stays in charge of the one step that can lose the machine.

---

#### Compare and Contrast

| | Prompt only | Agent loop |
| :--- | :--- | :--- |
| Instructions | the chat | `AGENTS.md`, `CLAUDE.md`, runbooks, memory |
| Build | 🥉 the human runs it | 🥇 `kernel-build`, every core |
| Install | 🥉 copy-pasted commands | 🥇 stripped modules, GRUB default, DKMS rules |
| Result checked by | the human, by hand | 🥇 the agent, from logs and counts the shell computes |
| A lesson learned | lost when the chat ends | 🥇 a memory file, then a runbook, then a script |
| Sign-off and submission | 🥇 human | 🥇 human, as `coding-assistants.rst` requires |

---

#### So, Is the Kernel-pocalypse a Bad Thing?

No. The loop lowers the bar to useful kernel work. Building mainline, installing it safely, reading a boot log, tracing an error to a commit and testing a one-line fix used to need a kernel developer at each step. With the scaffolding in place, one person directs the work and reviews the result, and the agent does the build, install and log reading.

The kernel's own rules keep that safe: reproduce first, build without warnings, say what was not tested, and leave the sign-off and the email to a human. A loop that follows them produces evidence a maintainer can check.

---

#### Summary

The goal of this article was to show a coding agent doing mainline kernel work in a closed loop, on more than one platform. The key to the solution was the scaffolding: mainline's `AGENTS.md` and `coding-assistants.rst` for the process, a few markdown runbooks and memory files for each machine, and one script for build and install. The results were:

- 🟢 Mainline 7.4-rc2 built and installed on a Yoga 9i, with stripped modules: an 88MB initrd against 641MB unstripped.
- 🟢 The new build became the GRUB default from the script, checked against `grub.cfg`.
- 🟢 A boot and log check by the agent: taint 0, no oops or warnings, 58 of 62 kernel error lines from the BIOS, clean suspend and resume.
- 🟢 A 7.4-rc2 sound regression fixed locally with the same line as the upstream fix, `d00ba321499c`, which arrived the next day.
- 🟢 One repo for the loop on Intel, two Windows-on-ARM laptops and a Pixel 3a.
- ⚠️ NVIDIA machines still need the hand install in a clean environment.
- ⚠️ The agent never signs off or submits. A human reviews every change, as the kernel requires.

Scope: one Lenovo Yoga 9i (i7-1360P) on Debian with GCC 16.2.0, mainline 7.4-rc2, Claude Code 2.1.325, boot and logs checked on 2026-11-15. The ARM and Android work is from the same repo, measured on those machines and written up in the articles below.

The strategy for kernel development with a coding agent was validated with an incremental step by step approach.

---

#### References

- Repository: https://github.com/xbill9/kernel_vibe_coding
- Install runbook: [intel/docs/KERNEL-INSTALL.md](https://github.com/xbill9/kernel_vibe_coding/blob/main/intel/docs/KERNEL-INSTALL.md)
- AI Coding Assistants: [Documentation/process/coding-assistants.rst](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/process/coding-assistants.rst)
- Tool-generated content: [Documentation/process/generated-content.rst](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/process/generated-content.rst)
- The ASoC fix: [d00ba321499c](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=d00ba321499c)
- Debian on the Galaxy Book Go: [linux-arm-adventures](https://github.com/xbill9/linux-arm-adventures/tree/main/articles/galaxy-book-go-debian)
- Debian on the Yoga C630: [linux-arm-adventures](https://github.com/xbill9/linux-arm-adventures/tree/main/articles/c630-debian)
- Pixel 3a eBPF backport: [android_kernel_google_msm-4.9](https://github.com/xbill9/android_kernel_google_msm-4.9/tree/main/backport-tools)
- Cover: drawn with Nano Banana 2 Lite from Tux by Larry Ewing (lewing@isc.tamu.edu) and The GIMP: [Tux.svg on Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Tux.svg)
