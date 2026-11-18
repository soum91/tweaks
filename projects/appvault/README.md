# AppVault Decryptor (rootless Sileo package)

**Sileo source:** https://raw.githubusercontent.com/soum91/tweaks/main/sileo/

**Upstream:** https://github.com/soum91/AppVault

**Release:** https://github.com/soum91/AppVault/releases/tag/v0.6.5

**Package ID:** `com.soum91.appvault` (preserved for existing Sileo upgrades)

**Installed app bundle:** `com.soum91.appvault.decryptor` (new separate rootless app)

## Why two applications?

The old 0.6.4 privileged rootless AppVault's WebKit WebContent process terminated
before it could load the SAP signing page on the user's Dopamine/iOS 16.1.1
device. That prevented Apple Account login before 2FA, independently of the
verification-code field.

From 0.6.5, Sileo installs only the privileged **AppVault Decryptor**
application. It scans installed user apps, creates independent decrypted copies
where authorized and technically possible, verifies output and exports IPA
files. Its native build does not include the Apple Store authentication client,
WebKit, or the SAP/WASM runtime.

Separately, the ordinary **AppVault IPA** (bundle `com.soum91.appvault`)
retains the sandboxed Apple Account login, Store search, authorized IPA
downloads and stock decryption-helper preparation. Install it through a normal
iOS sideloader such as FlareStore or EmberSign. The two apps intentionally have
different bundle identifiers and distinct icons. No credential relay is used.

The ordinary Store IPA and rootless Decryptor **do not** automatically share
sessions or downloaded files. Decryptor handles eligible apps **already
installed** on the same jailbroken phone; it does not decrypt an uninstalled,
newer-version App Store download.

**Device testing:** Native GitHub compilation and distribution integrity are
verified. Working Apple sign-in and FairPlay decryption on a physical device
remain unverified. No 2FA/DRM circumvention is claimed.

## Publishing

`scripts/sync_appvault.py` verifies the newest AppVault rootless DEB GitHub
release SHA-256, Debian version, package identity and maintainer, then mirrors
the original, unmodified package into `sileo/local`. The shared catalog
includes its content hash and retains old packages for cached Sileo indexes.

## Existing data

Upgrading package `com.soum91.appvault` updates its rootless icon from
`AppVault.app` to `AppVaultDecryptor.app` without touching the separately
sideloaded AppVault IPA or the existing rootless export directory at
`/var/mobile/Library/Application Support/com.soum91.appvault/Exports`.
