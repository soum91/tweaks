import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class SafetyContract(unittest.TestCase):
 def test_capability_changes_are_runtime_only(self):
  source=(ROOT/'src/Tweak.m').read_text()
  self.assertNotIn('com.apple.MobileGestalt.plist',source)
  self.assertNotIn('CacheData',source)
  self.assertNotIn('setKernelAlwaysOnMode',source)
  self.assertNotIn('setAlwaysOnDisabledByAssertion',source)
  self.assertNotIn('isAlwaysOnEnabled\",NO',source)
 def test_target_gates(self):
  s=(ROOT/'src/Shared.h').read_text()
  self.assertIn('iPhone14,3',s); self.assertIn('16.1.1',s)
  self.assertIn('if(!LATarget()) return;', (ROOT/'src/Tweak.m').read_text())
 def test_export_has_independent_paths(self):
  s=(ROOT/'src/App.m').read_text()
  for evidence in ['isEqual:self.report','UIActivityViewController','UIDocumentPickerViewController','v.selectable=YES']:
   self.assertIn(evidence,s)
