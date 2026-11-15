import pathlib,plistlib,sys
app=pathlib.Path(sys.argv[1]); root=pathlib.Path(__file__).resolve().parents[1]
version=next(x.split(': ',1)[1] for x in (root/'packaging/control').read_text().splitlines() if x.startswith('Version:'))
info=dict(CFBundleIdentifier='com.soum91.luminaod',CFBundleExecutable='LuminAOD',CFBundleName='LuminAOD',CFBundleDisplayName='LuminAOD',CFBundlePackageType='APPL',CFBundleShortVersionString=version,CFBundleVersion='1',MinimumOSVersion='16.1.1',UIDeviceFamily=[1],LSRequiresIPhoneOS=True,UILaunchScreen={},UIRequiredDeviceCapabilities=['arm64'],UISupportedInterfaceOrientations=['UIInterfaceOrientationPortrait'])
# A UIKit-drawn icon, generated reproducibly from vector primitives with Pillow.
from PIL import Image,ImageDraw
for n in (120,180):
 im=Image.new('RGB',(n,n),'#101523');d=ImageDraw.Draw(im);d.rounded_rectangle((n*.28,n*.12,n*.72,n*.88),radius=n*.09,outline='#7fe0ca',width=max(2,n//30));d.rounded_rectangle((n*.4,n*.17,n*.6,n*.20),radius=n*.01,fill='#7fe0ca');d.ellipse((n*.37,n*.34,n*.63,n*.60),outline='#eef6ff',width=max(2,n//45));d.line((n*.5,n*.38,n*.5,n*.47,n*.56,n*.5),fill='#eef6ff',width=max(2,n//45));d.rounded_rectangle((n*.41,n*.71,n*.59,n*.74),radius=n*.01,fill='#7fe0ca');im.save(app/f'Icon{n}.png')
info['CFBundleIcons']={'CFBundlePrimaryIcon':{'CFBundleIconFiles':['Icon120','Icon180'],'UIPrerenderedIcon':False}}
(app/'Info.plist').write_bytes(plistlib.dumps(info))
