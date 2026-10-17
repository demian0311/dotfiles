---
name: eagle-mbp-sound-camera
description: "How sound (CS8409 amps) and the FaceTime HD camera were fixed on eagle, the MacBook Pro; verified working 2026-10-16."
metadata:
  node_type: memory
  type: project
  originSessionId: 32ff254d-1822-48f5-9737-1a8270d46d83
  modified: 2026-10-16T21:18:29.972Z
---

`eagle` is a MacBook Pro running Omarchy.

- **Sound:** the stock CS8409 codec driver never switches the speaker amplifiers on. Fixed with the AUR package `snd-hda-macbookpro-dkms-git`, which installs a patched `snd-hda-codec-cs8409.ko` under `/lib/modules/<kernel>/updates/dkms/`. Check with `modinfo -n snd_hda_codec_cs8409`.
- **Camera:** Broadcom 1570 FaceTime HD on PCIe, not USB, so uvcvideo does not apply. The `facetimehd` driver exposes `/dev/video0`, YUYV only, 320x240–1296x736.
- **Verified 2026-10-16 by the user:** speakers (L/R), mic record/playback, and the camera in mpv all work after a reboot.
- Test: `speaker-test -c 2 -t wav -l 1`; `pw-record`/`pw-play`; `mpv av://v4l2:/dev/video0`.
- Both are DKMS modules: a kernel update rebuilds them. If sound or camera breaks after an update, check `dkms status` first.

See [[omarchy-privilege-escalation]] for running root steps.

2026-10-16 20:46: no sound after the first working lid suspends (see [[eagle-lid-suspend]]); PipeWire side was fine (speaker port, unmuted, stream active). Do NOT rebind 0000:00:1f.3 (`snd_hda_intel` unbind/bind) to recover: the DKMS cs8409 re-probe fails with `!(driver->ops && driver->ops->probe)`, error -22, and the analog device disappears until reboot. Reboot is the only known recovery. Whether resume itself silences the amps is not yet confirmed.
