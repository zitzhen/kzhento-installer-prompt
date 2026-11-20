# KzhenTo Installer Prompt — 安全测试指南 / Safety Testing Guide

原则：**不要把 deb 直接 `dpkg -i` 到日常使用的宿主机**。这个包会往 `/usr/bin`、`/usr/libexec`、`/usr/share/wayland-sessions` 写文件，其启动脚本还会接管 Wayland 会话。请按下面从低风险到高风险的顺序测试。

**EN:** Rule of thumb: **never `dpkg -i` this deb on your daily-driver host.** The package writes to `/usr/bin`, `/usr/libexec`, and `/usr/share/wayland-sessions`, and its startup helper takes over the Wayland session. Work through the steps below from lowest to highest risk.

下文中 `DEB` 指构建产物路径，`OUT` 指产物所在目录，按你的实际情况替换。

**EN:** Below, `DEB` is the path to the built package and `OUT` the directory containing it; replace both with your actual paths.

```sh
OUT=/path/to/deb-output
DEB="$OUT"/kzhento-installer-prompt_*_amd64.deb
```

## 1. 静态检查（零风险） / Static checks (zero risk)

查看包内文件清单、权限、控制信息与依赖，并解包到临时目录（不安装）。

**EN:** Inspect the file list, permissions, control metadata and dependencies, then extract the package to a temporary directory without installing it.

```sh
# 看包内文件清单和权限 / list files and permissions
dpkg-deb -c "$DEB"

# 看控制信息、依赖、版权 / show control metadata, dependencies and copyright
dpkg-deb -I "$DEB"
dpkg-deb --ctrl-tarfile "$DEB" | tar -xO ./control

# 解包到临时目录 / extract without installing
mkdir -p /tmp/kzhento-test
dpkg-deb -x "$DEB" /tmp/kzhento-test
find /tmp/kzhento-test -type f -printf '%m %p\n' | sort
```

重点确认：两个 libexec 脚本带可执行位，desktop 文件位于 `usr/share/wayland-sessions/`，依赖包含 Qt6 与 KF6 NetworkManagerQt。

**EN:** Verify that both libexec helpers are executable, the desktop entry is under `usr/share/wayland-sessions/`, and the dependencies include Qt6 and KF6 NetworkManagerQt.

## 2. 容器内安装测试（推荐，宿主机零改动） / Install inside a container (recommended, zero host changes)

```sh
docker run --rm -it -v "$OUT:/out:ro" ubuntu:26.04 bash
# 容器内 / inside the container（若需要 universe 里的包，先启用 universe / enable universe first）:
apt update
apt install -y /out/*.deb
dpkg -L kzhento-installer-prompt
apt-cache show kzhento-installer-prompt
```

无显示环境下的冒烟测试：

**EN:** Smoke test without a display:

```sh
timeout 5 env QT_QPA_PLATFORM=offscreen /usr/bin/kzhento-installer-prompt; echo "exit=$?"
```

`exit=124`（超时）说明进程正常存活；段错误或 Qt 插件报错才是问题。

**EN:** `exit=124` (timeout) means the process stayed alive; segfaults or Qt plugin errors are the real problems.

## 3. 看到真实 GUI：虚拟屏截图 / See the real GUI: virtual display screenshot

宿主机没有图形会话也没关系，用 Xvfb 起一个虚拟屏，跑起来后直接截图。

**EN:** No graphical session on the host is needed. Start a virtual display with Xvfb, run the app, and capture a screenshot.

```sh
# 容器内安装工具（一次即可）/ install tools once inside the container
apt install -y xvfb imagemagick

export DISPLAY=:99
Xvfb :99 -screen 0 1280x800x24 -nolisten tcp &
XPID=$!
sleep 1
env LANG=C.UTF-8 DISPLAY=:99 /usr/bin/kzhento-installer-prompt &
GPID=$!
sleep 6
kill -0 "$GPID" 2>/dev/null && echo ALIVE || echo EXITED
import -window root /out/gui.png
kill "$GPID" "$XPID" 2>/dev/null || true
```

把容器里的 `/out/gui.png` 拷出来查看即可。正常应看到 Kzhento Logo、`Try KzhenTo` / `Install KzhenTo` 两个按钮，以及 Language / Connection 下拉框。这两个下拉框在容器里通常是空的（没有真实 locale 和 NetworkManager），属于正常现象，不是界面缺陷。

**EN:** Copy `/out/gui.png` out of the container and open it. You should see the KzhenTo logo, the `Try KzhenTo` / `Install KzhenTo` buttons, and the Language / Connection drop-downs. The drop-downs are usually empty inside a container (no real locale or NetworkManager); that is expected, not a UI defect.

## 4. 宿主机直接运行解包出的二进制（不安装） / Run the extracted binary on the host (no install)

宿主机已装运行库时，可直接跑解包目录里的二进制；资源通过 qrc 内嵌，不依赖外部图片文件。

**EN:** If the host already has the runtime libraries, you can run the extracted binary directly; resources are embedded via qrc, so no external image files are needed.

```sh
cd /tmp/kzhento-test
timeout 8 env QT_QPA_PLATFORM=offscreen ./usr/bin/kzhento-installer-prompt; echo "exit=$?"
```

若要以真实界面看效果，用 X11/Wayland 平台（`QT_QPA_PLATFORM=xcb` 或默认 Wayland），但**注意**：

**EN:** To see the real interface, use the X11/Wayland platform (`QT_QPA_PLATFORM=xcb` or the default Wayland), but **note**:

- **不要点 "Install KzhenTo"**：它会执行 `xhost si:localuser:root` 和 `sudo ... calamares -D8`，会真的启动安装器。

  **EN: Do not click "Install KzhenTo"** — it runs `xhost si:localuser:root` and `sudo ... calamares -D8`, which really launches the installer.
- 点 "Try KzhenTo" 相对安全，只是让程序退出。

  **EN:** Clicking "Try KzhenTo" is comparatively safe; it just exits the program.
- 语言下拉框选择后可能触发 `change-system-language`（改 locale、键盘布局并重启 sddm），在宿主机上测试时不要真的切换语言。

  **EN:** Selecting a language may trigger `change-system-language` (changes locale and keyboard layout and restarts sddm); do not actually switch languages when testing on the host.

## 5. 完整功能测试（虚拟机 / 实际 Live ISO） / Full functional test (VM or real Live ISO)

只有这一层能验证首屏流程：SDDM 会话、Wayland 启动、网络选择、Calamares 交接。

**EN:** Only this level validates the first-boot flow: the SDDM session, Wayland startup, network selection and the hand-off to Calamares.

- 用 VirtManager / QEMU 建一个虚拟机，挂载构建好的 KzhenTo Live ISO。

  **EN:** Create a VM with VirtManager/QEMU and attach the built KzhenTo Live ISO.
- 观察 SDDM 会话列表里出现 "KzhenTo Live Environment"，进入后应看到新 Logo 和 "Try KzhenTo" / "Install KzhenTo" 按钮。

  **EN:** Confirm "KzhenTo Live Environment" appears in the SDDM session list; on entry you should see the new logo and the "Try KzhenTo" / "Install KzhenTo" buttons.
- 测 OEM 模式：在内核命令行加 `oem-config/enable=true`，应直接进入 `calamares-launch-oem` 而不显示提示器。

  **EN:** To test OEM mode, add `oem-config/enable=true` to the kernel command line; it should go straight to `calamares-launch-oem` without showing the prompt.
- 不要在装有重要数据的物理机上跑安装分支。

  **EN:** Never exercise the install branch on a physical machine that holds important data.

## 6. 清理 / Cleanup

```sh
rm -rf /tmp/kzhento-test
docker rm -f kzhento-debbuild   # 若不再需要构建容器 / only if no longer needed
```

宿主机始终没有安装该包，无需 `dpkg -r`。

**EN:** The host never had the package installed, so there is no need for `dpkg -r`.
