import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class SourceContractTests(unittest.TestCase):
    def test_rootless_identity(self):
        text = (ROOT / "control").read_text()
        self.assertIn("Package: com.soum91.chatgptlegacy16", text)
        self.assertIn("Architecture: iphoneos-arm64", text)
        self.assertIn("Maintainer: soum91", text)
        self.assertIn("Conflicts: com.liam.chatgbefree", text)

    def test_target_and_tweak_filter(self):
        makefile = (ROOT / "Makefile").read_text()
        self.assertIn("THEOS_PACKAGE_SCHEME := rootless", makefile)
        self.assertIn("TARGET := iphone:clang:latest:16.1", makefile)
        self.assertIn('com.openai.chat', (ROOT / "ChatGBeFree.plist").read_text())

    def test_source_and_gpl_attribution(self):
        for name in ["VoiceBridge/LegacyVoiceBridge.m", "VoiceBridge/LegacyRealtimeVoice.m",
                     "ImageBridge/LegacyImageBridge.m", "ModelSwitcher/LegacyModelSwitcher.m", "LICENSE"]:
            self.assertTrue((ROOT / name).is_file(), name)
        self.assertIn("GNU GENERAL PUBLIC LICENSE", (ROOT / "LICENSE").read_text())
        self.assertIn("liamschwie", (ROOT / "README.md").read_text())
        self.assertIn("not a completed", (ROOT / "README.md").read_text().lower())

if __name__ == "__main__":
    unittest.main()
