import hashlib
import unittest
from pathlib import Path
import importlib.util

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/sync_appvault.py"
spec = importlib.util.spec_from_file_location("appvault_sync", SCRIPT)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


def release(version="0.5.0", **overrides):
    data = b"example"
    asset = {
        "name": f"AppVault-{version}-rootless.deb",
        "browser_download_url": f"https://github.com/soum91/AppVault/releases/download/v{version}/AppVault-{version}-rootless.deb",
        "state": "uploaded", "size": len(data),
        "digest": "sha256:" + hashlib.sha256(data).hexdigest()
    }
    asset.update(overrides)
    return {"draft": False, "published_at": "2026-11-17T00:00:00Z",
            "tag_name": "v" + version, "assets": [asset]}


class AppVaultReleaseTests(unittest.TestCase):
    def test_first_matching_published_rootless_release(self):
        v, url, size, digest = sync.select_release([release("0.6.0"), release("0.5.0")])
        self.assertEqual(v, "0.6.0")
        self.assertEqual(size, 7)
        self.assertEqual(digest, hashlib.sha256(b"example").hexdigest())
        self.assertEqual(url, "https://github.com/soum91/AppVault/releases/download/v0.6.0/AppVault-0.6.0-rootless.deb")

    def test_accepts_build_numbered_asset_names(self):
        named = release("0.6.7", name="AppVault-0.6.7-20-rootless.deb",
                        browser_download_url="https://github.com/soum91/AppVault/releases/download/v0.6.7/AppVault-0.6.7-20-rootless.deb")
        v, url, _, _ = sync.select_release([named, release("0.6.5")])
        self.assertEqual(v, "0.6.7")
        self.assertEqual(url, "https://github.com/soum91/AppVault/releases/download/v0.6.7/AppVault-0.6.7-20-rootless.deb")
        wrong_tag = release("0.6.7", name="AppVault-0.6.8-20-rootless.deb")
        with self.assertRaises(ValueError):
            sync.select_release([wrong_tag])

    def test_excludes_drafts_and_nonmatching_assets(self):
        draft = release()
        draft["draft"] = True
        self.assertEqual(sync.select_release([draft, release("0.5.0")])[0], "0.5.0")
        with self.assertRaises(ValueError):
            sync.select_release([draft])

    def test_rejects_unexpected_source_and_unhashed_packages(self):
        with self.assertRaises(ValueError):
            sync.select_release([release(browser_download_url="https://other.example/file.deb")])
        with self.assertRaises(ValueError):
            sync.select_release([release(digest="")])


if __name__ == "__main__":
    unittest.main()
