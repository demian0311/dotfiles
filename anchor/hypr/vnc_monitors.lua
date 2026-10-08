-- The VNC virtual screens (wayvnc-fit creates them; this places them).
-- Installed by dotfiles anchor/install.sh, required from monitors.lua.
--
-- 🔴 They must never overlap each other or the real monitor. Hyprland maps the
-- pointer to whichever screen it finds first at a point, so an overlap sends a
-- viewer's clicks and keys to a screen nobody is watching (#1155, 2026-10-08:
-- both sat at 0x0 and eagle's input landed on the Mac's screen).
-- 🔴 They must be rules in the config, not `hyprctl eval` at runtime: an eval'd
-- rule is lost on the next reload, and the screens fall back to the catch-all.
-- Far left and far down, so the mouse at the desk cannot reach them.
hl.monitor({ output = "HEADLESS-VNC", mode = "2560x1020@60", position = "-2560x10000", scale = 1 })
hl.monitor({ output = "HEADLESS-EAGLE", mode = "1416x852@60", position = "-1416x20000", scale = 1 })
