# ChatGPT Legacy 16 native compatibility bridge

**Status: source and build validation only. Not a completed or device-verified port of ChatGPT 1.2026.314.**

A native-injection compatibility route for a jailbroken iPhone on iOS 16.1.1. It extends the **official, older ChatGPT 1.2024.200** application in place, rather than attempting to load the incompatible 2026 Mach-O binary. No ChatGPT IPA or proprietary OpenAI framework is distributed here.

## Provenance and license

Source was imported from [liamschwie/ChatGBeFree](https://github.com/liamschwie/ChatGBeFree), upstream v2.4.0 source as inspected on 2026-11-19. Upstream author attribution and original README are preserved in `UPSTREAM_README.md` and `LICENSE` (GPL-3.0). This fork has a separate Sileo identity, `com.soum91.chatgptlegacy16`, to prevent overwriting the upstream package. Do not install both. Upstream explicitly labels v2.4.0 a **prerelease not tested on physical hardware during release preparation**.

## Target and capability boundaries

- Device: iPhone 13 Pro Max, iOS 16.1.1, Dopamine rootless, arm64.
- Requires an independently obtained, official compatible ChatGPT **1.2024.200** installation. The provided 2023 IPA is **not** the target supported by these bridges.
- Bridges attempt to restore legacy app startup, session/version compatibility, realtime voice, account-advertised model selection, generated-image loading, and Markdown copying using the app's native components.
- No unlock of account entitlements, no undocumented OpenAI API keys, and no claim that every 2026 feature is available.
- No physical iOS 16.1.1 tests or successful sign-in, model, image, and voice validations have been performed for this fork.

## Build

```sh
export THEOS=/path/to/theos
make -C projects/chatgpt16 clean package
```

The rootless `.deb` is created in `projects/chatgpt16/packages/` if Theos compilation and packaging succeed. The CI build workflow uploads only a build artifact, **not** a Sileo release. Public deployment requires successful device verification and the repository's package/version/changelog tests.

## 2026 binary-port track

The distinct binary-rewrite investigation is recorded in [NATIVE_2026_BACKPORT.md](NATIVE_2026_BACKPORT.md). ChatGPT 1.2026.314's main core has 733 direct SwiftUI symbols absent from the permissive iOS 16.1 SDK export comparison. An ARM64 retain/release shim for 48 routines and 122 symbol redirects do not address the SwiftUI/Observation ABI. The incomplete experimental 2026 IPAs should not be installed as functional backports.
