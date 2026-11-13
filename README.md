# soum91 Tweaks

Canonical Sileo/APT repository for first-party rootless jailbreak packages.

Add this source in Sileo:

`https://raw.githubusercontent.com/soum91/tweaks/main/sileo/`

The `sileo/` directory contains the generated APT indexes, verified package
artifacts, checksums, and the source metadata used to refresh the catalog.
The package projects remain in their own repositories; this repository is the
stable distribution point. The former Daybreak-hosted catalog remains as a
compatibility mirror while clients migrate.

## Local rebuild

```sh
python3 scripts/build_tweaks_repo.py
python3 -m unittest discover -s tests -p 'test_tweaks_repo.py' -v
```
