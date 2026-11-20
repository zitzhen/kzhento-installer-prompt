# KzhenTo Installer Prompt

`kzhento-installer-prompt` is the welcome screen shown when a KzhenTo live ISO boots. It lets the user pick a language and a network connection, then offers **Try KzhenTo** (boot straight into the live desktop) or **Install KzhenTo** (hand off to the Calamares installer).

This is a KzhenTo-specific derivative of Kubuntu's `kubuntu-installer-prompt`, maintained by ZIT Studio. The project is in beta.

## Features

- **Language selection** built from `/usr/share/i18n/SUPPORTED` and `QLocale`. When offline, only a small set of locales (zh-Hans, hi, es, fr, ar, en) can install full language packages; other choices only change the Plasma language.
- **Network setup** through NetworkManagerQt over D-Bus: Ethernet and Wi-Fi device selection, a password dialog, and cleanup of connections that fail to authenticate. The device list refreshes every 15 seconds.
- **OEM mode**: if `oem-config/enable=true` is in the kernel command line, the prompt is skipped and `calamares-launch-oem` is started instead.
- **Multi-monitor support**: secondary screens show a plain background window while the prompt runs on the primary screen.

## Boot flow (Wayland)

1. SDDM loads, and Casper points `/etc/sddm.conf` at the `kubuntu-live-environment.desktop` session. The filename is retained for compatibility with the base ISO.
2. The session runs `/usr/libexec/start-kubuntu-live-env`.
3. The script starts `kwin_wayland --xwayland --no-lockscreen` with `kubuntu-installer-prompt` as its client (or `calamares-launch-oem` in OEM mode).
4. The prompt appears and the user chooses **Try KzhenTo** or **Install KzhenTo**.
5. **Install KzhenTo** runs `xhost si:localuser:root` followed by `sudo QT_QPA_PLATFORMTHEME=kde calamares -D8`, then hides the buttons. When Calamares closes, the prompt exits.
6. **Try KzhenTo** makes the prompt exit immediately.
7. After the prompt exits, the script installs a one-shot autostart entry to restart the XDG desktop portals and launches `startplasma-wayland`.

## Building

Requirements:

- CMake 3.16 or newer and a C++23 compiler
- Extra CMake Modules (ECM), Qt 6 (Core, Widgets, Network, LinguistTools), and KF6 NetworkManagerQt
- Debian build dependencies are listed in `debian/control`

```sh
cmake -S . -B build
cmake --build build
cmake --install build
```

The install prefix is `/usr`. The build installs the `kubuntu-installer-prompt` binary, the `change-system-language` and `start-kubuntu-live-env` helpers under `libexec`, and the live-session desktop entry under `share/wayland-sessions`.

## Testing

Do not install the built deb on your daily-driver host. See `TESTING.md` (bilingual, Chinese and English) for a step-by-step guide that starts with zero-risk static checks, runs the package inside a container, renders the GUI on a virtual display, and only then moves on to a VM or Live ISO.

## Translations

Translation templates live in `src/translations/` and currently contain no finished translations. After changing any UI string, regenerate them with:

```sh
./gen_ts.sh
```

The script prefers a Qt 6 `lupdate` binary (`lupdate-qt6` or `/usr/lib/qt6/bin/lupdate`) and falls back to `lupdate`. At build time CMake compiles the `.ts` files into `.qm` resources via `qt_add_translation`.

To add a language:

1. Add its locale code to `langList` in `gen_ts.sh` and run the script.
2. Re-run CMake so the `file(GLOB ...)` in `CMakeLists.txt` picks up the new `.ts` file.
3. Add a matching `<file alias="LOCALE">kubuntu-installer-prompt_LOCALE.qm</file>` line inside the `<qresource>` tag in `src/translations.qrc`.

Translators can then fill in the new template; the compiled translation is picked up at runtime according to the system locale.

## Naming kept from upstream

The following names are intentionally unchanged from the Kubuntu original so the ISO integration and packaging keep working: the executable `kubuntu-installer-prompt`, the Debian package name, `scripts/start-kubuntu-live-env`, `scripts/change-system-language`, `kubuntu-live-environment.desktop`, and the translation file names. Only the CMake project name was changed, to `kzhento-installer-prompt`.

## Artwork and licensing

- `img/kzhento-logo.png` — **The KzhenTo Logo. Copyright (C) 2026 ZIT Studio. All rights reserved.** Adapted from artwork published at <https://github.com/zitzhen/kzhento-icon>. This artwork is **excluded** from the GPL-3.0 license covering the rest of this project; no permission to use, copy, modify, or distribute it is granted here. Contact ZIT Studio for permission.
- `img/background.png` — Copyright (C) 2024 Fábio Maricato and Michael Mikowski. CC0-1.0 Universal. Designed for Kubuntu.
- `img/arrow-down.svg`, `img/dialog-warning.svg` — Copyright (C) 2014 Uri Herrera and others. LGPL-3.0-or-later. From the Breeze icon theme.
- `img/usb-drive.svg`, `img/hdd-drive.svg` — Copyright (C) 2014 Uri Herrera and others, Copyright (C) 2024 Kubuntu Contributors. LGPL-3.0-or-later. Adapted from the Breeze icon theme.

All other files are licensed under GPL-3.0-or-later. Original copyright: 2022 Lubuntu Developers and 2024 Kubuntu Developers; derivative changes copyright 2026 ZIT Studio. The unmodified GPL-3.0 text, together with the ZIT Studio derivative notice, is in `LICENSE`.

## Origin

Derivative of `kubuntu-installer-prompt`, originally from <https://git.launchpad.net/~kubuntu-packagers/kubuntu-packaging/+git/kubuntu-installer-prompt>.
