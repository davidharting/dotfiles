# Kinesis Freestyle Edge RGB

Backup of the keyboard's onboard **v-Drive** contents. This is reference/recovery
material only — it is NOT stowed (`install.sh` skips `docs/`). To restore, mount
the v-Drive and copy these files back, then eject to apply.

- Firmware: KBD 1.0.121.us (4MB), LED 1.0.58
- USB IDs: vendor `10730`, product `258`

## Mounting the v-Drive

`v_drive=manual` in `settings/kbd_settings.txt`, so it mounts on demand via the
keyboard's v-Drive hotkey rather than automatically. **Eject it to apply changes** —
the keyboard re-reads the layout on eject.

macOS writes `._*` AppleDouble files onto this FAT volume. Delete them before
ejecting to keep the 3.9 MB drive clean.

## layouts/layout1.txt — the Mac modifier layout

Active layout (`startup_file=layout1.txt`). Remaps the Windows-default bottom row
to Mac modifier positions. Syntax is `[physical]>[emitted]`, and each mapping is
repeated under the `fn` layer.

| Line | Physical key | Emits | macOS sees |
|---|---|---|---|
| `[lwin]>[alt]`   | Left Win   | Alt      | Option |
| `[lalt]>[lwin]`  | Left Alt   | Left Win | Command |
| `[ralt]>[rwin]`  | Right Alt  | Right Win| **Right** Command |
| `[rctrl]>[alt]`  | Right Ctrl | Alt      | Option |

### Why `[ralt]` must map to `[rwin]`, not `[lwin]`

SmartSet's macOS preset generates `[ralt]>[lwin]`, which collapses the right-side
command key onto **left** GUI. That feels correct — it behaves as Command — but it
silently breaks any Karabiner rule keyed on `right_command`, because the keyboard
never emits right GUI at all. Karabiner cannot work around this: the key is
indistinguishable from the real left command key.

This is what broke the Hyper key (`right_command` → `cmd+ctrl+option+shift`).
Diagnosed with Karabiner-EventViewer, which reported `left_command` when pressing
the right-of-space Command key.

**If you ever re-run the SmartSet macOS preset, it will regress this line.**
Re-apply `[ralt]>[rwin]` afterward.

## Related

- Karabiner config: `karabiner/.config/karabiner/karabiner.json` (stowed)
- Hyper is modifier-emitting (real `cmd+ctrl+option+shift`) so Raycast can bind it
