# AGENTS.md

SDDM login-screen theme written in QML (no build step, no tests, no lint). The
theme is installed to `/usr/share/sddm/themes/pixie` and rendered by the SDDM
greeter.

## Project layout

- `src/` — the SDDM theme source (flat, mirrors the installed theme dir):
  `Main.qml`, `metadata.desktop`, `theme.conf`, `components/`, `assets/` (images
  only), and `Preview.png` (referenced by `metadata.desktop` `Screenshot=`).
- `lockscreen/` — the KDE Plasma 5 lock screen port (see below).
- `vendor/fonts/` — the single source of truth for all bundled fonts + licenses.
  Install scripts copy the `.ttf` files into the runtime `assets/fonts/` dirs
  (SDDM and lockscreen); do not edit fonts in place, edit here.
- Root: meta files (`AGENTS.md`, `README.md`, `LICENSE`, `.gitignore`) and the
  two install scripts. QtCreator artifacts (`pixie.*`, `.qtc_clangd/`) are
  gitignored.

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
- `Main.qml` imports `"components"`; new components go in `src/components/` and
  are auto-available, but must be copied by both install paths below.

## Two install paths must stay in sync

A new theme file only reaches users if added to the install scripts:
1. `install.sh` — the `cp -r src/* ...` line (plus `vendor/fonts/` for fonts).
2. `flake.nix` — the `lib.fileset.unions [...]` list (this is the source of
   truth for what the Nix package ships; README/screenshots are intentionally
   excluded). Note `flake.nix` exists only on the `main` branch.

The theme directory name is `pixie` (used in both `install.sh` `THEME_DIR` and the
flake `installPhase`); keep it consistent with `services.displayManager.sddm.theme = "pixie"`.

Fonts are NOT kept in `src/assets/fonts` — `install.sh` copies them from
`vendor/fonts/` into `${THEME_DIR}/assets/fonts/`.

## Versioning

`metadata.desktop` `Version=` and `flake.nix` `version` (on `main`) are both
`3.0`; bump them together.

## KDE lock screen port (`lockscreen/`, qt5 branch only)

A separate optional port of the theme for KDE Plasma 5's `kscreenlocker`
(native lock screen, `Super+L`), because SDDM themes do **not** run on the lock
screen. It lives in `lockscreen/` and is installed by `install-lockscreen.sh`
(not `install.sh`, not `flake.nix`).

- `kscreenlocker` loads `contents/lockscreen/LockScreen.qml` from the
  look-and-feel package that the active theme falls back to
  (`org.kde.breeze.desktop` by default). The installer copies that whole package
  to `~/.local/share/plasma/look-and-feel/<id>/` (so the package's `metadata.json`
  with `X-Plasma-APIVersion: "2"` stays present) and swaps in the pixie
  `lockscreen/`. Fonts are copied in from `vendor/fonts/`. No root, survives
  package updates.
- API differs from SDDM: `sddm.login()` → `authenticator.respond(password)`;
  user/avatar → `kscreenlocker_userName` / `kscreenlocker_userImage`;
  suspend → `root.suspendToRam()`; failures → `authenticator.onFailed`.
  `config.*` here is the kcfg schema from `lockscreen/config.xml` (Bool/Color,
  **not** strings like the SDDM `theme.conf`).
- The wallpaper is rendered by `FastBlur { source: wallpaper }`; it must stay
  visible in idle (vary `radius`, not `opacity`) or the background goes black.
  Keep mouse handling to `onClicked`/`Keys.onPressed` — `onPositionChanged`/
  `hoverEnabled` fire spuriously at startup and force the password prompt.
- Preview with `kscreenlocker_greet --testing`
  (`/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing`).
