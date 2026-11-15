"""Validate installable contents, Mach-O architectures and runtime version metadata."""
import pathlib,plistlib,subprocess,sys,tempfile,struct
p=pathlib.Path(sys.argv[1]).resolve()
assert subprocess.check_output(['dpkg-deb','-f',str(p),'Package'],text=True).strip()=='com.soum91.luminaod'
assert subprocess.check_output(['dpkg-deb','-f',str(p),'Architecture'],text=True).strip()=='iphoneos-arm64'
with tempfile.TemporaryDirectory() as d:
 subprocess.run(['dpkg-deb','-x',str(p),d],check=True)
 root=pathlib.Path(d); app=root/'var/jb/Applications/LuminAOD.app'
 info=plistlib.loads((app/'Info.plist').read_bytes())
 assert info['CFBundleShortVersionString']==subprocess.check_output(['dpkg-deb','-f',str(p),'Version'],text=True).strip()
 assert info['CFBundleVersion']=='1'
 assert (app/'Icon180.png').is_file()
 data=(root/'var/jb/Library/MobileSubstrate/DynamicLibraries/LuminAOD.dylib').read_bytes()
 assert struct.unpack_from('>I',data)[0]==0xcafebabe
 n=struct.unpack_from('>I',data,4)[0]; assert n==2
 subtypes=[]
 def signed_macho(data):
  assert struct.unpack_from('<I',data)[0]==0xfeedfacf
  ncmds,sz=struct.unpack_from('<II',data,16);offset=32; signature=False
  for _ in range(ncmds):
   cmd,size=struct.unpack_from('<II',data,offset);assert size>=8
   if cmd==0x1d:
    start,length=struct.unpack_from('<II',data,offset+8);assert start+length<=len(data);assert struct.unpack_from('>I',data,start)[0]==0xfade0cc0;signature=True
   offset+=size
  assert signature,'Missing code signature'
 for i in range(n):
  cpu,sub,off,size,align=struct.unpack_from('>IIIII',data,8+i*20)
  assert cpu==0x100000c;subtypes.append(sub&0xffffff)
  if sub&0xffffff==2: assert sub&0x80000000, "Old arm64e ABI: rebuild with Xcode 12+; do not publish"
  signed_macho(data[off:off+size])
 assert set(subtypes)=={0,2},subtypes
 signed_macho((app/'LuminAOD').read_bytes())
 assert not (root/'var/containers').exists(), 'System cache must never be packaged'
 print('Verified rootless paths, arm64 + arm64e signed tweak, signed app, icons, and installed version',info['CFBundleShortVersionString'],info['CFBundleVersion'])
