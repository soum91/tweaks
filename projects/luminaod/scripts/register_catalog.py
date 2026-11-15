"""Register the verified local package without dropping existing catalog sources."""
import json,pathlib,subprocess
root=pathlib.Path(__file__).resolve().parents[3]
path=root/'sileo/local/com.soum91.luminaod_0.1.0_iphoneos-arm64.deb'
subprocess.run(['python3',str(pathlib.Path(__file__).with_name('validate.py')),str(path)],check=True)
file=root/'sileo/sources.json'; config=json.loads(file.read_text())
entry={'name':'LuminAOD','local_deb':str(path.relative_to(root)),'packages':['com.soum91.luminaod']}
if not any('com.soum91.luminaod' in s['packages'] for s in config['sources']): config['sources'].append(entry)
file.write_text(json.dumps(config,indent=2)+'\n')
