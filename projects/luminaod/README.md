# LuminAOD

Rootless Dopamine tweak and companion editor for **iPhone 13 Pro Max
(iPhone14,3), iOS 16.1.1**. Other models/versions do not install any hooks.
Package: `com.soum91.luminaod`, version 0.1.0, app build 1.

## Install and use

Add `https://raw.githubusercontent.com/soum91/tweaks/main/sileo/` in Sileo,
install **LuminAOD**, open the LuminAOD home-screen app, and tap **Respring**.
Native pipeline is enabled by default. Lock the phone and check whether the
actual screen stays visible and the clock advances. Native operation is
**experimental and has not been verified on a physical device**.

If the native pipeline produces a black screen or does not update, open
LuminAOD, choose **Mode > Live Lock Screen**, respring, and lock again. This
fallback uses Apple's existing live Cover Sheet with its clock, wallpaper,
widgets and notifications at 3% brightness. It is **not equivalent to native
low-power AOD**, keeps the application processor/display active, and cannot
supply the 14 Pro panel's 1 Hz hardware behavior. Prolonged display use can
increase power use and OLED wear. No claim of matching native power use,
brightness curves, privacy redaction, or every native transition is made.

In live mode, a touch restores brightness and releases the idle hold. The
next normal screen-off can enter live mode again. Pressing the side button
while live mode is active releases the hold and leaves the screen off until
the next manual wake. Low Power Mode, serious thermal state, proximity and
face-down orientation release the hold; screen-off then follows normal iOS
idle timing. Camera/passcode/remote content and leaving the main lock-screen
page also release the hold. Sleep Focus, Watch-away detection, and
native-style notification redaction are not implemented in the fallback.

## Native path

This does more than set an iOS 18 preset on iOS 16. It hooks these existing
native iOS 16 selectors after verifying their ABI:

- `+[SBBacklightPlatformProvider deviceSupportsAlwaysOn]`
- `-[SBAlwaysOnDefaults forceAndromedaSupport]`
- `-[SBAlwaysOnDefaults enableAlwaysOn]`
- `-[BLSHBacklightOSInterfaceProvider deviceSupportsAlwaysOn]`

It also overrides the iOS 16-era `DeviceSupportsAlwaysOnTime` query and its
obfuscated alias in SpringBoard and Settings. `DeviceSupportsAlwaysOnDisplay`
and AOD vibrancy keys introduced in later iOS versions are not advertised as
an iOS 16 solution. CoreBrightness and flipbook completion callbacks are logged
without suppressing their errors. Native policy assertions for low power,
thermal conditions, focus, sensitive content, and setup are not overridden.
No kernel/display mode values are rewritten and no fake driver acknowledgments
are injected. If Apple's pipeline needs hardware the 13 Pro Max lacks, these
user-space support hooks may be insufficient.

## Runtime MobileGestalt editor

Browse/search the read-only CacheExtra fields or add a key. Save an override
as Boolean, Integer, Real or String, then respring. Overrides apply to
`MGCopyAnswer` and `MGGetBoolAnswer` only in SpringBoard and Settings while
master Enabled is on. Other processes and direct typed/multiple-answer APIs
are outside this editor's scope. Unknown keys may have no effect. In native
mode the preset owns the AlwaysOnTime query.

**The system MobileGestalt plist and CacheData are never written.** Only this
package's preferences and diagnostic status files are written. Disable and
clear overrides, then respring to recover original answers. A normal reboot
without re-jailbreaking also removes runtime changes. To uninstall, remove
LuminAOD in Sileo and restart SpringBoard or reboot.

## Diagnostics

The app exposes software-reported native enabled state, numeric backlight and
flipbook state, installed hook names, and bounded transition logs. A software
"enabled" flag is not proof of visible native AOD or working hardware flipbooks.
Reports have verified clipboard read-back, native Share, native Save to Files,
and selectable full text. Cross-app Copy/Share/Save and physical display
behavior still require signed-device verification. Override values are omitted
from reports to avoid disclosing potentially sensitive user-entered values.

## Build

The workflow uses the pinned Theos iOS 16.5 SDK and a modern Apple compiler,
packages an arm64 + current-ABI arm64e dylib plus an arm64 companion app, and
signs both ad hoc for Dopamine. The validator rejects old arm64e ABI slices,
missing signatures, missing icons, metadata mismatches and incorrect rootless
paths. The Sileo catalog is only updated after compilation and validation.

On macOS, install `dpkg`, `ldid` and Pillow, then set `SDKROOT`, `CC`, `LDID`,
`LIPO` and run `bash projects/luminaod/scripts/build.sh` from the repository
root. Run `python3 scripts/check_version_ui.py` and
`python3 -m unittest discover -s projects/luminaod/tests -v` first.
