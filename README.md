# Kzhento Installer Prompt

This project is in beta. It presents a "Try or Install Kzhento" screen. It is the Kzhento-specific derivative of the Kubuntu live installer prompt.

Art assets are copyrighted as follows:

* img/arrow-down.svg, img/dialog-warning.svg: Copyright (C) 2014 Uri Herrera <uri_herrera@nitrux.in> and others. LGPL-3+ license. Taken from the Breeze icon theme.
* img/usb-drive.svg, img/hdd-drive.svg: Copyright (C) 2014 Uri Herrera <uri_herrera@nitrux.in> and others, Copyright (C) 2024 Kubuntu Contributors. LGPL-3+ license. Adapted from the Breeze icon theme.
* img/background.png: Copyright (C) 2024 Fábio Maricato, Copyright (C) 2024 Michael Mikowski <mmikowski@kfocus.org>. CC0-1.0 Universal license. Designed for Kubuntu.
* img/kzhento-logo.png: Kzhento wordmark by Oliver Lin (Iamliuxiaozhen), from https://github.com/zitzhen/kzhento-icon. Recolored and cropped for the dark live-session background by ZIT Studio. The source repository currently has no explicit license file; add one before redistributing the artwork publicly.

All other files are licensed under the GNU General Public License version 3. Copyright (C) 2022 Lubuntu Developers <lubuntu-devel@lists.ubuntu.com>, Copyright (C) 2024 Kubuntu Developers <kubuntu-devel@lists.ubuntu.com>.

Derivative changes Copyright (C) 2026 ZIT Studio. This is a derivative of kubuntu-installer-prompt, originally from https://git.launchpad.net/~kubuntu-packagers/kubuntu-packaging/+git/kubuntu-installer-prompt. The GNU GPL version 3 license text is preserved unchanged in LICENSE.

## Architecture

This section explains how the Kzhento ISO's live prompt fits together.

1. SDDM loads.
2. Casper points `/etc/sddm.conf` at the `kubuntu-live-environment.desktop` session (the filename is kept for compatibility with the base ISO).
3. The session runs `/usr/libexec/start-kubuntu-live-env`.
4. The script starts `kwin_wayland --xwayland --no-lockscreen` with `kubuntu-installer-prompt` as its client. If `oem-config/enable=true` is in the kernel command line, `calamares-launch-oem` is started instead and the prompt is skipped.
5. The installer prompt appears.
6. The user clicks "Install Kzhento" or "Try Kzhento".
7. On "Install Kzhento", the prompt runs `xhost si:localuser:root` followed by `sudo QT_QPA_PLATFORMTHEME=kde calamares -D8`, then hides its buttons.
8. When Calamares closes, the prompt detects this and exits.
9. The script drops a one-shot autostart entry to restart the XDG desktop portals, then runs `startplasma-wayland`.
10. On "Try Kzhento", steps 8 and 9 are executed immediately.

## Translations

Run the `gen_ts.sh` script after making any code modifications to ensure that the translations files are up-to-date for translators to work on.

To add a new language to be translated:

* Open the `gen_ts.sh` script and add the locale code for the new language to the `langList` array.
* Run the script after doing this - a new template .ts file will be generated under `src/translations/`.
* Next, add the new template file to the `TS_FILES` list in `CMakeLists.txt` - it will be named `src/translations/kubuntu-installer-prompt-locale_CODE.ts`, where `locale_CODE` is the locale code of the added language.
* Finally, add a line in the src/translations.qrc resource file to include the new translation file. The line should look like `<file alias="locale_CODE">kubuntu-installer-prompt_locale_CODE.qm</file>`, where `locale_CODE` is the locale code of the added language. This line should go inside the `<qresource>` tag.

For instance, if I were to add Chinese to the list of languages that could be translated into, I would do this:

    vim gen_ts.sh
    # add this code to the langList array:
    #    'zh_CN'
    ./gen_ts.sh
    vim CMakeLists.txt
    # add this line to the TS_FILES list:
    #    src/translations/kubuntu-installer-prompt_zh_CN.ts
    vim src/translations.qrc
    # add this line to the list of file resources:
    #    <file alias="zh_CN">kubuntu-installer-prompt_zh_CN.qm</file>

The program will now pick up the added language at build time. Any translations added to the newly created .ts file will be shown to program users who select the new language.
