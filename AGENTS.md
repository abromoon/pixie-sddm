# AGENTS.md

SDDM login-screen theme written in QML (no build step, no tests, no lint). The
theme is installed to `/usr/share/sddm/themes/pixie` and rendered by the SDDM
greeter.

## Branches: Qt6 vs Qt5

- `main` = Qt6 (uses `QtQuick.Effects`, `MultiEffect`). Default for Fedora/Arch/Nix.
- `qt5` = legacy Qt5 branch (uses `QtGraphicalEffects`). Default for Ubuntu/Debian.
- `install.sh` auto-detects the installed greeter (`sddm-greeter-qt6` vs
  `sddm-greeter`) and `git checkout`s the matching branch. Keep Qt5-only changes
  on the `qt5` branch, not `main`.
- `metadata.desktop` declares `QtVersion=6`; do not change per-branch casually.

## No build/test commands — preview instead

There is no package manager, test runner, or linter here. Verify a change by
installing and running the greeter in test mode:

```bash
sudo ./install.sh                          # installs to /usr/share/sddm/themes/pixie
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/pixie   # Qt6
sddm-greeter      --test-mode --theme /usr/share/sddm/themes/pixie   # Qt5
```

## QML gotchas

- `theme.conf` is the only config surface. `config.<key>` values come in as
  **strings**, so compare with `config.autoColor === "true"` /
  `config.use24HourClock !== "true"` — never a boolean literal.
- `config` object and the SDDM globals (`sddm`, `userModel`, `sessionModel`,
  `battery`, `keyboard`) only exist inside the greeter. `Main.qml` already guards
  them with `typeof ... !== "undefined"`; keep that pattern for new code.
- `Main.qml` imports `"components"`; new components go in `components/` and are
  auto-available, but must be copied by both install paths below.

## Two install paths must stay in sync

A new file only reaches users if added to BOTH:
1. `install.sh` — the `cp -r assets components Main.qml metadata.desktop theme.conf LICENSE` line.
2. `flake.nix` — the `lib.fileset.unions [...]` list (this is also the source of
   truth for what the Nix package ships; README/screenshots are intentionally excluded).

The theme directory name is `pixie` (used in both `install.sh` `THEME_DIR` and the
flake `installPhase`); keep it consistent with `services.displayManager.sddm.theme = "pixie"`.

## Versioning

`metadata.desktop` `Version=` and `flake.nix` `version` are both `3.0`; bump them
together.
