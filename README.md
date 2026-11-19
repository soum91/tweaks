# soum91 Tweaks

Canonical Sileo/APT repository for first-party rootless jailbreak packages.

Add this source in Sileo:

`https://raw.githubusercontent.com/soum91/tweaks/main/sileo/`

The `sileo/` directory contains the generated APT indexes, verified package
artifacts, checksums, and the source metadata used to refresh the catalog.
New tweak projects live under `projects/` in this repository. Existing packages
retain their compatibility sources while they migrate. The former Daybreak-hosted catalog remains as a
compatibility mirror while clients migrate.

## Local rebuild

```sh
python3 scripts/build_tweaks_repo.py
python3 -m unittest discover -s tests -p 'test_tweaks_repo.py' -v
```

## Projects

- [LuminAOD](projects/luminaod/): experimental native AOD support hooks, live lock-screen fallback, and reversible runtime MobileGestalt editor for iPhone 13 Pro Max / iOS 16.1.1.

- [ChatGPT Legacy 16](projects/chatgpt16/): experimental native 2024-client compatibility bridges; distinct from the unfinished 2026 binary backport (not published to Sileo).
