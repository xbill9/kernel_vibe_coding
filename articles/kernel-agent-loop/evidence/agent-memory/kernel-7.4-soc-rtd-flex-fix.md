<!-- Claude Code memory file from yoga9i, copied 2026-11-15. Verbatim except the originSessionId line. -->
---
name: kernel-7-4-soc-rtd-flex-fix
description: "SOF/ASoC no-mic bug under GCC 16 in 7.4-rc2; fixed upstream by d00ba321499c (pulled 2026-11-14), local edit dropped"
metadata:
  type: project
---

7.4-rc2 commit 4dd10fbbeb9c switched the ASoC runtime alloc in `soc_new_pcm_runtime()` to `devm_kzalloc_flex()`. With GCC 16 (`__builtin_counted_by_ref`) that presets `rtd->num_components` to the capacity, so `for_each_rtd_components()` sees nothing, no component is probed (no SOF topology load) and `snd_soc_rtd_add_component()` writes past the array. Symptom: `fail to add hda routes, ret -19`, no sound card, no DMIC. Fix: `rtd->num_components = 0;` after the alloc — an uncommitted edit in ~/linux, installed on 2026-11-13 by replacing only snd-soc-core.ko.xz (stripped, signed, xz) and reloading the sound modules; verified the card, both DMIC PCMs and mic signal.

**Update 2026-11-14:** upstream merged the same fix as d00ba321499c "ASoC: soc-core: reset rtd->num_components after allocation"; the local edit was discarded on `git pull` (tree at 97d73c825122). Any kernel built from a tree containing d00ba321499c has the fix.

**How to apply:** no local patch needed any more. Same day: BTF and regulatory.db checks passed; NVIDIA needed a forced DKMS rebuild, see [[kernel-install-nvidia-dkms]].
