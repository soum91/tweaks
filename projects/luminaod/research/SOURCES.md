# Evidence and implementation boundary

Reviewed 2026-11-15. These are primary code/header sources; headers establish
selector availability, not successful display behavior on an unsupported panel.

- iOS 16.0 runtime header index (SDK/platform 16.0):
  https://github.com/donato-fiore/iOS-Runtime-Header-Browser
- Native platform support and policies:
  https://github.com/donato-fiore/iOS-Runtime-Headers/blob/main/16.0/PrivateFrameworks/SpringBoard.framework/Headers/SBBacklightPlatformProvider.h
- enableAlwaysOn and forceAndromedaSupport defaults:
  https://github.com/donato-fiore/iOS-Runtime-Headers/blob/main/16.0/PrivateFrameworks/SpringBoardFoundation.framework/Headers/SBAlwaysOnDefaults.h
- CoreBrightness interface and completion selectors:
  https://github.com/donato-fiore/iOS-Runtime-Headers/blob/main/16.0/PrivateFrameworks/BacklightServicesHost.framework/Headers/BLSHBacklightOSInterfaceProvider.h
- Actual idle-hold API used by the fallback:
  https://github.com/donato-fiore/iOS-Runtime-Headers/blob/main/16.0/PrivateFrameworks/SpringBoard.framework/Headers/SBDashBoardIdleTimerController.h
- MobileGestalt key mapping:
  https://github.com/PoomSmart/MGKeys/blob/master/deobfuscated.py
- Theos arm64e ABI requirement:
  https://theos.dev/docs/arm64e-deployment
- Apple states 14 Pro AOD uses a new 1 Hz display mode:
  https://www.apple.com/ie/newsroom/2022/09/apple-debuts-iphone-14-pro-and-iphone-14-pro-max/

Do not interpret later-OS `DeviceSupportsAlwaysOnDisplay` or `DeviceSupportsAODVibrancy`
MobileGestalt presets as a verified iOS 16 unlock. Do not claim native AOD works
until lock, minute updates, notifications, wake, proximity, focus and restoration
have been tested on the target device. No hardware-driver success is faked here.
