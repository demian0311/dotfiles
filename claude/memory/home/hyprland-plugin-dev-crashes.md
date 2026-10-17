---
name: hyprland-plugin-dev-crashes
description: 2026-10-16/17 the home-built eagle-zoom Hyprland plugin killed the compositor twice; the two mechanisms and the dev loop that avoids them.
metadata:
  node_type: memory
  type: project
  originSessionId: f0f39fd4-0f7d-416d-850f-dd4e5f6a53e5
  modified: 2026-10-17T06:12:17.812Z
---

On eagle, Hyprland 0.56.2 died twice on 2026-10-16/17 while another session iterated on the Ctrl + two-finger zoom plugin (`~/code/dotfiles/eagle/zoom`, dotfiles #10). Diagnosed and fixed 2026-10-17, dotfiles #12, commit c8da1af. Zoom gesture confirmed working by the user 2026-10-17 00:15; #10 closed.

1. **23:10** SIGSEGV inside `dlclose` ← `CPluginSystem::unloadPlugin`: install.sh hot-unloaded the already-loaded copy before loading the rebuilt one.
2. **00:03** `symbol lookup error: ... undefined symbol: _Z14lua_pushnumberP9lua_Stated`: `lua.h` included without `extern "C"`, so the reference was C++-mangled; lazy binding let the build and `hyprctl plugin load` succeed, and the first zoom call aborted the whole compositor.

**Why:** a plugin runs inside the compositor, so every window dies with it. Lazy binding and hot-unload each turned a plugin bug into a session loss.

**How to apply:** link Hyprland plugins with `-Wl,-z,now --no-gnu-unique` so a bad build fails at load with a readable error. Never `hyprctl plugin unload` a loaded plugin; install the file and log out/in. Test a new build in a nested Hyprland first: `Hyprland --config <minimal.conf>` as a window, `hyprctl -i <new signature under /run/user/1000/hypr> plugin load <so>`, then `dispatch exit`. Check `nm -D x.so | grep ' U .*lua'` shows plain C names. Hyprland itself links `liblua.so.5.5`, so C-named Lua symbols resolve from the host. Related: [[libinput-3fg-drag-eats-4fg-swipe]], [[eagle-touchpad-dwt-quirk]].
