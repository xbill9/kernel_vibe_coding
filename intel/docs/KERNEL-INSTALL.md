#### Building and installing mainline on x86 (Debian)

Notes for the Intel machines that run kernels built from `~/linux`: `yoga9i` (Yoga 9i, Raptor Lake-P, i915), `gpu` (i7-5820K, RTX 3050) and `yogagpu`. Each item was observed on the date given.

---

#### Step 1 — Build

```sh
kernel-build --no-install      # pull, olddefconfig, make -j$(nproc)
```

A fresh tree starts from `/boot/config-$(uname -r)`, with Debian's signing keys blanked and `LOCALVERSION=-mainline`. The working config has `CONFIG_RUST=y` and `CONFIG_DEBUG_INFO_BTF=y`.

---

#### Step 2 — Install with stripped modules

```sh
sudo make -j$(nproc) INSTALL_MOD_STRIP=1 modules_install && sudo make install
```

With `CONFIG_DEBUG_INFO=y`, a plain `modules_install` puts full DWARF in every module: `/lib/modules/<rel>` was 1.3G and the initrd 641MB (measured 2026-11-14). With `INSTALL_MOD_STRIP=1` they were 118M and 88MB, and the `.BTF` sections are kept. The serial install took about 20 minutes, against 35 seconds with `-j16` on the Yoga 9i. Use `-j$(nproc)` so the same command fits every machine.

Check `/boot/initrd.img-<rel>` is about 90MB afterwards.

🟢 `scripts/kernel-build` does this step with `-j$JOBS` (default `nproc`).

---

#### Step 3 — Make the new build the boot default

A build is meant to be run. `GRUB_DEFAULT` in `/etc/default/grub` is pinned to a `gnulinux-<release>-advanced-<uuid>` id, so `make install` alone leaves the old kernel booting.

1. Back up `/etc/default/grub`.
2. Swap the release in the id for the new one.
3. `sudo update-grub`.
4. Confirm the id exists in `/boot/grub/grub.cfg`.

🟢 `scripts/kernel-build` does this after `make install`: it swaps the release in a pinned id, keeps a dated backup of `/etc/default/grub`, and restores it if the new id is missing from `grub.cfg`. A numeric or `saved` `GRUB_DEFAULT` is left alone.

On `gpu`, `GRUB_DEFAULT=0` and the newest kernel sorts first, so the new build is already the default. Confirm entry 0's `linux` line in `grub.cfg`.

---

#### Step 4 — NVIDIA DKMS (machines with an NVIDIA card)

`sudo make install` breaks the NVIDIA DKMS build. The kernel's install target exports `KERNELRELEASE`, the `/etc/kernel/postinst.d/dkms` hook inherits it, and NVIDIA's Makefile then runs `include $(src)/Kbuild` with an empty `src` (`/Kbuild: No such file`). `run-parts` stops there, so the initramfs and `update-grub` hooks are skipped too (observed 2026-11-13).

Install by hand in a clean environment instead, after `modules_install`:

```sh
K=<kernelrelease>; V=<nvidia version>
sudo cp arch/x86/boot/bzImage /boot/vmlinuz-$K
sudo cp System.map /boot/System.map-$K
sudo cp .config /boot/config-$K
E="env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin HOME=/root"
sudo $E dkms remove nvidia/$V -k $K
sudo $E dkms install nvidia/$V -k $K
sudo $E update-initramfs -c -k $K      # -u if it already exists
sudo $E update-grub
```

🟢 `scripts/kernel-build` does this step when `dkms status` lists any module: it copies the three files, runs `dkms build --force` then `dkms install --force` for each module, then `update-initramfs` and `update-grub`, all under `env -i`. With no DKMS modules it runs `sudo make install`.

- Do not call `arch/x86/boot/install.sh` directly. It falls through to the LILO path and copies nothing.
- **Rebuilding the same kernel release:** `dkms install --force` only reinstalls the cached build from `/var/lib/dkms`. Run `dkms build nvidia/$V -k $K --force` first, then `dkms install ... --force`.
- A stale module fails with `modprobe: Exec format error` and repeated `x86/modules: Invalid relocation target, existing value is nonzero` in dmesg. `MODVERSIONS` is off, so vermagic alone does not catch it (seen on `gpu` and `yogagpu`, 2026-11-13).
- The `gpu` config uses `LOCALVERSION=-xbill-hsw` with `nova-core` off, so it does not contend with `nvidia` for the GA106.

---

#### Step 5 — Confirm the booted kernel is the new build

`tainted = 0` says the running kernel is clean. It does not say the running kernel is the one just built. A rebuild of the same release installs over `/boot/vmlinuz-<rel>` and `/lib/modules/<rel>`, and a suspend and resume keeps the old kernel running. On 2026-11-14 the Yoga 9i booted `#15` at 16:49, `#16` was installed at 17:18, and the next morning's checks read `#15`.

`kernel-build` stamps every build with a build ID: `KBUILD_BUILD_VERSION=<n>-<8 random hex>`, so `uname -v` reads `#17-3fa9c2d1 SMP PREEMPT_DYNAMIC ...`. It stops if the ID is missing from `include/generated/utsversion.h` after `make`, or from the version string of `/boot/vmlinuz-<rel>` after install. It then writes the release, the full `uname -v` string, the source and the commit to `~/.local/state/kernel-build/installed`.

After the reboot, run the check before recording anything:

```sh
kernel-boot-check
```

If `uname -r` or `uname -v` differs from the record, it prints both, prints nothing else and exits 1. Results from that boot belong to a different kernel; reboot and run it again. On a match it prints the build ID, then the taint flags, error counts, kernel warnings and failed units.

The worst case, `#99999-ffffffff SMP PREEMPT_DYNAMIC` plus the date, is 64 characters, the limit the kernel's `cut -b -64` allows.

---

#### Known issue — 7.4-rc2 no microphone (fixed upstream)

7.4-rc2 commit `4dd10fbbeb9c` moved the ASoC runtime allocation in `soc_new_pcm_runtime()` to `devm_kzalloc_flex()`. With GCC 16 (`__builtin_counted_by_ref`) that presets `rtd->num_components` to the capacity, so no component is probed and the SOF topology never loads. Symptom: `fail to add hda routes, ret -19`, no sound card, no DMIC.

🟢 Fixed upstream by `d00ba321499c` "ASoC: soc-core: reset rtd->num_components after allocation" (pulled 2026-11-14). Any tree containing it needs no local patch.
