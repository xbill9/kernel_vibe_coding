# The kernel loop on the Intel machines: build and install, read the boot
# logs, check the docs. `make` with no target lists the targets.
#
# Variables:
#   NOPULL=1  install: build ~/linux as it is, skip git pull
#   KSRC, JOBS  passed through to kernel-build (default ~/linux, nproc)
#   FORCE=1   install-scripts: replace a ~/bin copy that differs from the repo
#   BASE=-N   loop: compare with journal boot -N instead of the last other build
#   LIVE=1    article: also fetch every published URL in the preflight
#   PUBKIT    publishing kit scripts (default ~/publishing-kit/skills/publishing/scripts)

SHELL       := /bin/bash
.SHELLFLAGS := -euo pipefail -c

BINDIR  ?= $(HOME)/bin
PUBKIT  ?= $(HOME)/publishing-kit/skills/publishing/scripts
ARTICLE ?= articles/kernel-agent-loop/devto-kernel-agent-loop.md
SCRIPTS := intel/scripts/kernel-build intel/scripts/kernel-boot-check \
           intel/scripts/kernel-log-compare \
           intel/scripts/hw-update

.PHONY: help install install-scripts feedback loop docs docs-check article

help:
	@sed -n 's/^\([a-z-]*\):.*## \(.*\)/  make \1|\2/p' $(MAKEFILE_LIST) | column -t -s '|'

install: ## build ~/linux and install it: stripped modules, GRUB default (arm64: c630-menu entry, default unchanged), build ID record
	intel/scripts/kernel-build $(if $(NOPULL),--no-pull)

install-scripts: ## symlink the loop's scripts into ~/bin, so repo edits are live
	@for s in $(SCRIPTS); do \
	  src=$(CURDIR)/$$s dest=$(BINDIR)/$$(basename $$s); \
	  if [[ -L $$dest && $$(readlink $$dest) == "$$src" ]]; then \
	    echo "ok      $$dest"; continue; \
	  fi; \
	  if [[ -e $$dest && ! -L $$dest ]] && ! cmp -s "$$src" "$$dest" && [[ -z "$(FORCE)" ]]; then \
	    echo "differs $$dest (diff it against $$s, or FORCE=1)" >&2; exit 1; \
	  fi; \
	  ln -sfn "$$src" "$$dest"; echo "linked  $$dest -> $$src"; \
	done

feedback: ## after a reboot: confirm the running kernel is the installed build, then read the boot logs
	intel/scripts/kernel-boot-check

loop: ## build ID check, then this boot's logs against the last boot of another build: new, gone, counts
	@intel/scripts/kernel-boot-check >/dev/null || intel/scripts/kernel-boot-check
	intel/scripts/kernel-log-compare $(BASE)

docs: docs-check article ## both doc checks below

docs-check: ## broken local links and repo paths in every tracked markdown file
	tools/check-doc-links.py

article: ## rebuild the article's Medium version and run the publishing preflight
	@[[ -d "$(PUBKIT)" ]] || { echo "no publishing kit at $(PUBKIT); set PUBKIT=" >&2; exit 1; }
	cd $(dir $(ARTICLE)) && python3 $(PUBKIT)/make-medium.py $(notdir $(ARTICLE)) medium
	cd $(dir $(ARTICLE)) && python3 $(PUBKIT)/preflight.py $(notdir $(ARTICLE)) $(if $(LIVE),--live)
