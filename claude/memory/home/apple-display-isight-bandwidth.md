---
name: apple-display-isight-bandwidth
description: The LED Cinema Display's iSight on anchor fails above 320x240 from USB isoc bandwidth; uvcvideo quirks=128 fixes YUYV to 640x480 but MJPEG still fails.
metadata:
  type: project
---

`anchor`'s webcam is the **Apple LED Cinema Display iSight** (`05ac:8508`) on the
display's built-in hub, sharing one high-speed bus with Display Audio
(`1-2.4`, full-speed isochronous), the keyboard hub, the Magic Mouse and the
display itself.

**Symptom:** capture fails above 320x240 with `VIDIOC_STREAMON returned -1
(Cannot allocate memory)`. The kernel log is explicit:

```
xhci_hcd 0000:00:14.0: Not enough bandwidth. Proposed: 1696, Max: 1607
usb 1-2.5: Not enough bandwidth for altsetting 7
```

Only ~5.5% over budget. Nothing is wrong with the driver binding, the device
nodes, or permissions — `demian` gets an ACL on `/dev/video0` from logind.

**Fix applied 2026-09-16:** `/etc/modprobe.d/uvcvideo-quirks.conf` containing
`options uvcvideo quirks=128` (`UVC_QUIRK_FIX_BANDWIDTH` = 0x80), which makes
uvcvideo compute the real payload size instead of trusting the camera's
inflated claim. Verified end to end with a real captured frame.

Results at 30fps with the quirk:

| mode | result |
|---|---|
| 320x240 / 640x480 **YUYV** | works |
| **any MJPEG** (640x480 → 1280x1024) | still fails |

**MJPEG can never be fixed by a quirk.** `uvc_fixup_video_ctrl` gates the whole
bandwidth correction on `!(format->flags & UVC_FMT_FLAG_COMPRESSED)`, so
compressed formats skip it entirely. Do not bother with `UVC_QUIRK_FORCE_BPP`
(0x1000) or `UVC_QUIRK_RESTRICT_FRAME_RATE` (0x200) — the latter pins the rate to
the device default, which is 30fps here, i.e. the failing mode.

**Chromium always prefers MJPEG and will not fall back to YUYV.** When STREAMON
returns ENOMEM it surfaces a generic `NotReadableError`, which Zoom displays as
**"your camera is being used by other apps"** — a misleading message that has
nothing to do with the device being busy. Check `journalctl -k` for
`Not enough bandwidth for altsetting 7` timestamps matching the attempt.

**Final working solution (2026-09-16): a v4l2loopback virtual camera.**
`v4l2loopback-dkms` + `/etc/modprobe.d/v4l2loopback.conf` with
`devices=1 video_nr=10 card_label="iSight Virtual Camera" exclusive_caps=1`,
fed by a user service at
`~/.config/systemd/user/isight-virtualcam.service` running:

```
ffmpeg -f v4l2 -input_format yuyv422 -video_size 640x480 -framerate 30   -i /dev/video0 -vf format=yuv420p -f v4l2 /dev/video10
```

`/dev/video10` then advertises exactly one format (YU12 640x480@30), so Chromium
has no failing option to choose. **In Zoom pick "iSight Virtual Camera", not
"Display iSight"** — the real device is held by ffmpeg and selecting it gives the
"in use by other apps" error. Service is `enabled` (starts at login); note
`Linger=yes` on this account, so it also runs while logged out.

Colour: one-shot grabs come out heavily yellow/green, but auto white balance
converges once the camera streams continuously, so the service output looks
correct. No filter needed.

The quirks param is **global**, overriding the built-in quirk table for any UVC
device. Harmless here: `05ac:8508` has no entry in the kernel's `uvc_ids[]`
table, so nothing is being discarded. Revisit if another webcam is ever plugged in.

Note `quirks = 4294967295` means *unset* (the `-1` sentinel), not "all quirks on".

**Zoom on this box is a Chromium web app** (`omarchy-webapp-handler-zoom`), not
the native client, so it takes the plain V4L2 path and is subject to all of the
above. Test the camera without a meeting using
`mpv av://v4l2:/dev/video0` or a one-frame `ffmpeg -f v4l2` grab.

Captured frames come out heavily yellow/green under warm room light; auto white
balance leaves `white_balance_temperature` inactive at 6500K.

See [[omarchy-privilege-escalation]] for how to run the root parts.
