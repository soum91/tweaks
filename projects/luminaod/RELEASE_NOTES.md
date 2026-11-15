## LuminAOD 0.1.0 (build 1)

First experimental release for iPhone 13 Pro Max on Dopamine iOS 16.1.1.

- Add runtime hooks for the native SpringBoard Always-On Display support check, forceAndromedaSupport and enableAlwaysOn defaults, plus the backlight OS-interface support getter.
- Override the iOS 16-era AlwaysOnTime MobileGestalt answer in SpringBoard and Settings; add a searchable runtime editor for Boolean, Integer, Real and String answers without writing the system cache.
- Add an explicit Live Lock Screen fallback using Apple's existing Cover Sheet at low brightness, with touch restoration and idle-hold release for proximity, face-down, low power, heat, passcode and leaving the lock screen main page.
- Add a companion app with actual installed version/build, disable/reset and respring controls, software backlight/hook status, and selectable diagnostics with verified Copy, native Share and Save to Files.
- Package for rootless Dopamine with signed arm64 and current-ABI arm64e slices; enforce package/version/signature/catalog checks before publishing.

Known limitations: native visible AOD and hardware flipbooks have not been tested on a physical iPhone 13 Pro Max. Support flags may be insufficient for its display hardware. The fallback keeps the display/processor awake and does not reproduce native power efficiency, every native transition, Sleep Focus, Watch-away detection or AOD privacy redaction. Copy/Share/Save have not been tested on a signed physical device. No system MobileGestalt cache is changed.

Source: https://github.com/soum91/tweaks/tree/main/projects/luminaod
