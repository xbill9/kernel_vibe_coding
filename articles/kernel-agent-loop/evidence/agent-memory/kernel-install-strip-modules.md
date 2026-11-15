<!-- Claude Code memory file from yoga9i, copied 2026-11-15. Verbatim except the originSessionId line. -->
---
name: kernel-install-strip-modules
description: "Install ~/linux builds with sudo make -j$(nproc) INSTALL_MOD_STRIP=1 modules_install, else initrd balloons to ~640MB"
metadata:
  node_type: memory
  type: project
  modified: 2026-11-14T22:20:55.608Z
---

The ~/linux config has CONFIG_DEBUG_INFO=y + DEBUG_INFO_BTF. A plain `sudo make modules_install` installs modules with full DWARF: /lib/modules/<rel> is 1.3G and the initrd 641MB (measured 2026-11-14). With `INSTALL_MOD_STRIP=1` it is 118M and the initrd 88MB, and `.BTF` sections are kept.

**Why:** a 641MB initrd risks GRUB load failure / slow boot; the serial install also took ~20 min vs 35s with -j16.
**How to apply:** `sudo make -j$(nproc) INSTALL_MOD_STRIP=1 modules_install && sudo make install`, then check /boot/initrd.img-<rel> is ~90MB. Then follow [[kernel-install-set-default]].
