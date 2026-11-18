# AppVault (rootless jailbreak package)

**Distribution:** The canonical Sileo source is
`https://raw.githubusercontent.com/soum91/tweaks/main/sileo/`.
The shared catalog mirrors the official AppVault rootless DEB, retaining its
original package identity, signing, bytes, dependencies, maintainer and version.

**Upstream implementation:** https://github.com/soum91/AppVault

**Upstream release:** https://github.com/soum91/AppVault/releases

**Install:** Add soum91 Tweaks to Sileo, refresh sources and install
`com.soum91.appvault`. On the jailbroken device, open AppVault and select
**IPAs > Decrypt Installed Apps (Jailbreak)**.

**Limits:** The ordinary FlareStore/sideloaded IPA is not a privileged jailbreak
package. AppVault downloads Apple-supplied encrypted IPAs by default; the
privileged rootless DEB provides a separate installed-app decryption/export path.
Physical-device FairPlay decryption and export remain unverified. A matching
Apple Account license and appropriate iOS compatibility are still required.

**Publishing:** `scripts/sync_appvault.py` verifies the latest published
AppVault rootless GitHub release's SHA-256 and Debian control metadata, and
updates `sileo/sources.json` and `sileo/local/`. Then
`scripts/build_tweaks_repo.py --sync` builds the complete combined index.
The hourly catalog job follows upstream releases without re-signing or
silently replacing existing package versions. The app and its main source
remain in AppVault; this directory documents the Sileo distribution
integration and does not pretend the full application was migrated.
