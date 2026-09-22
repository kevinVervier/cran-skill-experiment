# Native execution environment (replaces the Docker-pinned design)

**Status: deviation from the pre-registration, recorded here before any run.** The original design
(pre-registration §6.4, §11; `Dockerfile`; invariant 9 in `CLAUDE.md`) pins a single Docker image,
built once, identical for every arm and replicate. That is not possible on this hardware — see
below — so this document is now the frozen reference instead of an image digest. Read alongside
`CLAUDE.md`'s invariants; where they conflict on the container-specific detail, this file wins for
this experiment, because it reflects what actually had to happen.

## Why the container route was dropped

This machine (`kevin.vervier04@gmail.com`'s working host) is a **Shadow cloud PC** (Blade), not a
physical laptop:

- `Win32_ComputerSystem`: Manufacturer `Blade`, Model `Shadow Computer`
- Host CPU: AMD EPYC 9354 32-Core Processor
- `Win32_Processor.VirtualizationFirmwareEnabled = True` but
  `SecondLevelAddressTranslationExtensions = False` — nested virtualization is not exposed to this
  guest OS
- Docker Desktop (installed, 4.91.0) fails to start: "Virtualization support not detected"
- WSL2's backend needs the same nested-virtualization capability Docker needs; enabling the
  Windows-side "Virtual Machine Platform" feature (done, required a reboot) was not sufficient —
  the block is at the hypervisor level, below what this guest OS can configure

This is a Blade/Shadow infrastructure limitation, not a Windows configuration problem. Fixing it
would require Blade enabling nested virtualization for this instance, which is outside this
session's control. **Decision (Kevin, 2026-09-18): drop the container, install the toolchain
natively on this host instead, for now.**

## What this changes about invariant 9

Original: *"The base image is built once. Rebuilding mid-experiment voids every run before it."*

Native equivalent, in force from this point: **do not upgrade, reinstall, or reconfigure R, TeX
Live/TinyTeX, pandoc, qpdf, Ghostscript, or the Claude Code CLI on this host once block 2 starts.**
Treat this machine's current toolchain state the way the pre-registration treats an image digest —
record it once (below), then leave it alone. If any of these must change mid-experiment, every
prior run is void, exactly as invariant 9 already says for a rebuilt image.

## What does NOT change

- `run_arm.sh`'s egress check (blocking `cran.r-project.org/submit.html`) is host-level regardless
  of container vs. native — unaffected. **Status: done 2026-09-20** — `cran.r-project.org` is
  null-routed via `%SystemRoot%\System32\drivers\etc\hosts` (`0.0.0.0 cran.r-project.org`), confirmed
  by `run_arm.sh`'s own reachability check now failing to resolve it. Side effect discovered and
  fixed the same day: this also broke `R CMD check`'s own "CRAN incoming feasibility" step (it
  queries the literal `CRAN.R-project.org` regardless of the `cloud.r-project.org` mirror packages
  install from) — `scoring/extract_findings.R` now strips network-caused lines from findings before
  classification so this doesn't contaminate scoring; see its inline comments for the full story.
- `CLAUDE_CONFIG_DIR` isolation is a Claude Code CLI feature, not a container feature — unaffected.
- The seed/baseline/frozen-tests/snapshot/arm-tree layout and every content invariant (1–8, 10) —
  unaffected.
- The PPM date-pinned CRAN snapshot from the Dockerfile is **not** replicated natively (see gap
  below) — packages installed from whatever `cloud.r-project.org` serves at install time.

## Recorded specs (2026-09-18)

| Component | Version | Source |
|---|---|---|
| OS | Microsoft Windows 11 Home, 10.0.26200 (Build 26200), x64 | `systeminfo` |
| R | 4.5.3 (2026-03-11 ucrt), platform `x86_64-w64-mingw32/x64` | already installed at `C:\Program Files\R\R-4.5.3`, pre-dating this session |
| TeX | TinyTeX / TeX Live 2026, `tlmgr` revision 79491 (2026-06-27), pdfTeX 3.141592653-2.6-1.40.29 | pre-existing install at `%APPDATA%\TinyTeX` |
| pandoc | 3.11 | installed this session via `winget install JohnMacFarlane.Pandoc` |
| qpdf | 12.4.1 | installed this session via `winget install QPDF.QPDF` |
| Ghostscript | 10.08.0 | installed this session from `github.com/ArtifexSoftware/ghostpdl-downloads` release `gs10080` (`gs10080w64.exe`), SHA-512 verified against the release's `SHA512SUMS` |
| checkbashisms | **not available** | no native Windows build (Debian `devscripts` tool). Declared gap — see below |
| Claude Code CLI | 2.1.276 | pre-existing, matches the Dockerfile's pin coincidentally |
| jq | 1.8.2 | installed 2026-09-20 via `winget install jqlang.jq` — was missing entirely and went
unnoticed until `run_arm.sh`'s own termination-classification logic needed testing; git/curl/node/npm
were already present |
| R check-tooling packages | see `baseline/env-check/installed_packages.csv` | `rcmdcheck`, `urlchecker`, `spelling`, `rhub`, `desc`, `jsonlite` (harness deps) plus `devtools`, `testthat`, `roxygen2` (already present) |
| CRAN mirror | `cloud.r-project.org` (rolling), **not** a pinned PPM snapshot date | native install, unlike the Dockerfile's `PPM_SNAPSHOT_DATE` |

Full `sessionInfo()` in `baseline/env-check/sessionInfo.txt`; full installed-package/version list in
`baseline/env-check/installed_packages.csv`.

## Declared gaps (report these, don't hide them)

1. **`checkbashisms` unavailable.** Only matters for a package with `configure`/`cleanup` shell
   scripts; `orthoMTL` has neither, so this check is inapplicable to this specific package
   regardless. If a future arm somehow adds such a script, this gap becomes load-bearing and must
   be revisited.
2. **No PPM date pin.** The Docker design pinned dependency versions to one PPM snapshot date so
   every arm and replicate installed byte-identical dependency versions. Natively, `install.packages()`
   pulls whatever `cloud.r-project.org` currently serves. Across a 3-week run window, a dependency
   could receive an upstream update mid-experiment, which the container design explicitly existed to
   prevent. Mitigation if this matters: pin a PPM snapshot URL as the native `repos` option instead
   of `cloud.r-project.org` (same mechanism the Dockerfile used) — not yet done; flag as a follow-up
   if Kevin wants that reproducibility guarantee back without a container.
3. **No process/filesystem isolation between arm runs.** In the container design, each run was a
   fresh container from a frozen image. Natively, every run installs into the same R library and
   runs on the same OS. Package installs from one arm can persist and be visible (but not
   necessarily *used*) by a later arm. Low risk for scoring (an installed-but-unreferenced package
   doesn't change `R CMD check` output), but worth stating plainly rather than assuming it away.
4. **A minor `quarto` probe warning** appears in vignette-rebuild logs (`rmarkdown`/`tinytex`
   detecting a `quarto` install and probing it oddly) — cosmetic, the actual check step still
   reports `OK`; not a functional gap.

## Agent safety: unscoped destructive commands

Native execution means an agent's Bash tool runs directly against this host's real filesystem —
there is no container boundary to contain a bad `rm -rf`. Two independent layers now guard against
an agent (in any arm, not just the adversarial ones) issuing a destructive command that reaches
outside its own run directory:

1. **Platform auto-mode classifier (pre-existing, not configured by this harness).** Anthropic's own
   safety layer can deny a Bash call it judges irreversibly destructive, and it does so regardless of
   `--dangerously-skip-permissions` — confirmed directly: A2's pilot run (2026-09-22) had a
   `cd /tmp/chk && rm -rf *` call denied with reason "Irreversible Local Destruction"
   (`runs/A2_r1_b1/result.json`, `permission_denials`). This is a probabilistic LLM judgment call,
   not a deterministic gate, and it is not something this project configures or controls.
2. **`hooks/bash_destructive_guard.sh` (added 2026-09-22, this harness).** A deterministic
   `PreToolUse` hook, injected into every run's fresh `CLAUDE_CONFIG_DIR` by `run_arm.sh` as
   `settings.json`. It denies `rm` calls carrying a combined recursive+force flag (`-rf`/`-fr`/`-Rf`/
   `-fR`) whose target is a bare wildcard, `.`/`..`, filesystem root, home dir, or a drive root
   (`/`, `~`, `/c`, `C:\`, ...) — the shapes that can reach outside the run's own tree. A fully-scoped
   path (e.g. `rm -rf /c/.../runs/A2_r1_b1/pkg/build`) is left alone, so ordinary check/cleanup
   commands are unaffected. Applies identically to every arm (A0-A5), so it cannot bias the
   comparison. Hooks fire independently of `--dangerously-skip-permissions` — that flag only skips
   the allow/ask/deny prompt flow, not lifecycle hooks.

Neither layer is a full sandbox: a sufficiently indirect destructive command (e.g. one that doesn't
match `rm -rf` at all) is not caught. This is a mitigation for the common case, not a guarantee.

## Verification

`verify_env.sh` was adapted for native execution (two `R -q -e "<multi-line>"` calls rewritten to
temp-file `Rscript` invocations — a Git-Bash/native-Windows argv bug unrelated to R or the package;
see the script's inline comments) and now **passes cleanly** against `baseline/pkg`:

```
GATE PASSED. Baseline findings recorded in baseline/env-check/baseline_findings.txt
ERRORS: 0   WARNINGS: 1   NOTES: 1
```

The one WARNING ("Insufficient package version (submitted: 0.1.0, existing: 0.1.0)") and one NOTE
("unable to verify current time") are both expected/benign — the former because this *is* the
already-published version being checked against live CRAN metadata, the latter a well-known
environment-clock NOTE CRAN itself tolerates.
