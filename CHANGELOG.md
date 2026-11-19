# Changelog

## Unreleased (ChatGPT Legacy 16 native bridge source, 2026-11-19)

- Import the GPLv3 ChatGBeFree 2.4.0 compatibility source and tests under `projects/chatgpt16/` with upstream attribution.
- Create a separate rootless package identity and iOS 16.1 target, plus a macOS compile/package validation workflow without publishing a release.
- Document that ChatGPT 1.2026.314 cannot yet launch on iOS 16.1.1 because of unresolved SwiftUI/Observation imports. No runtime compatibility or sign-in success is claimed.


## [luminaod-v0.1.0] - 2026-11-15

## Verified changes since project start

- Add LuminAOD native iOS 16 support hooks and reversible capability editor ([`10e48fa8`](https://github.com/soum91/tweaks/commit/10e48fa80b47ee5d2b692ffa8b775d2f0ad77e2d); `.github/workflows/luminaod.yml`, `README.md`, `projects/luminaod/README.md`, and 17 more)
- Publish USBKeys 0.1.7 phone-only source trace recording ([`7872d187`](https://github.com/soum91/tweaks/commit/7872d1876ea7f88f0778383965afc5ac8ea5cb28); `sileo/Packages`, `sileo/Packages.bz2`, `sileo/Packages.gz`, and 5 more)
- Publish USBKeys 0.1.6 and follow live upstream package indexes ([`9db991ba`](https://github.com/soum91/tweaks/commit/9db991ba2f49b3c7f54cf6b3ead422a52182bcc2); `sileo/Packages`, `sileo/Packages.bz2`, `sileo/Packages.gz`, and 6 more)
- Publish canonical consolidated Sileo repository ([`ea8c657e`](https://github.com/soum91/tweaks/commit/ea8c657ec2fe36430169e5e35d9a0783cc68cab3); `.github/workflows/sync.yml`, `.gitignore`, `README.md`, and 28 more)

[Inspect exact code changes](https://github.com/soum91/tweaks/commits/luminaod-v0.1.0)

## LuminAOD 0.1.0 (build 1)

First experimental release for iPhone 13 Pro Max on Dopamine iOS 16.1.1.

- Add runtime hooks for the native SpringBoard Always-On Display support check, forceAndromedaSupport and enableAlwaysOn defaults, plus the backlight OS-interface support getter.
- Override the iOS 16-era AlwaysOnTime MobileGestalt answer in SpringBoard and Settings; add a searchable runtime editor for Boolean, Integer, Real and String answers without writing the system cache.
- Add an explicit Live Lock Screen fallback using Apple's existing Cover Sheet at low brightness, with touch restoration and idle-hold release for proximity, face-down, low power, heat, passcode and leaving the lock screen main page.
- Add a companion app with actual installed version/build, disable/reset and respring controls, software backlight/hook status, and selectable diagnostics with verified Copy, native Share and Save to Files.
- Package for rootless Dopamine with signed arm64 and current-ABI arm64e slices; enforce package/version/signature/catalog checks before publishing.

Known limitations: native visible AOD and hardware flipbooks have not been tested on a physical iPhone 13 Pro Max. Support flags may be insufficient for its display hardware. The fallback keeps the display/processor awake and does not reproduce native power efficiency, every native transition, Sleep Focus, Watch-away detection or AOD privacy redaction. Copy/Share/Save have not been tested on a signed physical device. No system MobileGestalt cache is changed.

Source: https://github.com/soum91/tweaks/tree/main/projects/luminaod


## USBKeys 0.1.7 (8): phone-only source trace

- Add timestamped source-side HID control metadata, callback/reply stages, interrupt transfer lengths/errors and native state transitions to report exports. Payloads and key values are omitted. No compatibility fix is claimed.


## USBKeys 0.1.6 (7)

- Mirror the signed upstream build enabling IN/OUT control completion callbacks and adding separate interrupt transfer counters. Correction: its address-to-token change is a no-op on native 20B101, whose allocation outputs 0 and 2 are identical; no root cause or working input fix has been demonstrated. Source commit: soum91/daybreak@87a9994185d3b83622853c743eba1e153414233c.
- Replace frozen local Daybreak and USBKeys source indexes with their live upstream indexes so the hourly job can discover future versions.
- Target iPhone input remains unverified.

## 2026-11-13

- Created the canonical `soum91/tweaks` Sileo repository.
- Consolidated seven verified rootless package artifacts and their APT indexes.
- Added an hourly verified catalog refresh workflow.
