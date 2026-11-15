<!-- Claude Code memory file from yoga9i, copied 2026-11-15. Verbatim except the originSessionId line. -->
---
name: kernel-install-set-default
description: "After building and installing a kernel, make it the GRUB default boot entry without asking"
metadata:
  node_type: memory
  type: feedback
  modified: 2026-11-13T16:40:23.916Z
---

When installing a freshly built kernel from ~/linux, also point GRUB_DEFAULT in /etc/default/grub at the new entry and run update-grub. GRUB_DEFAULT is pinned to a specific `gnulinux-<release>-advanced-<uuid>` id, so `make install` alone leaves the old kernel booting.

**Why:** User: "make the latst build the default not building just for fun" — a build is meant to be run.
**How to apply:** Back up /etc/default/grub, swap the release in the id, update-grub, confirm the id exists in /boot/grub/grub.cfg.
