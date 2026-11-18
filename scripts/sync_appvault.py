#!/usr/bin/env python3
"""Mirror the newest verified AppVault rootless release into the shared Sileo source.

The GitHub release is the binary source of truth. Never modify/re-sign the DEB.
The main catalog generator subsequently validates Debian metadata and indexes it.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
API = "https://api.github.com/repos/soum91/AppVault/releases?per_page=30"
SOURCE = "soum91/AppVault"
PACKAGE = "com.soum91.appvault"
MAX_BYTES = 16 * 1024 * 1024
ASSET = re.compile(r"^AppVault-(\d+\.\d+\.\d+)-rootless\.deb$")


def request_bytes(url, maximum):
    headers = {
        "User-Agent": "soum91-tweaks-sync",
        "Accept": "application/vnd.github+json" if url == API else "application/octet-stream",
        "Cache-Control": "no-cache",
    }
    # Public API calls without credentials hit shared low GitHub rate limits.
    # Only attach the Actions token to our exact GitHub API URL, never to
    # release redirects or third-party CDN addresses.
    if url == API:
        token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
        if token:
            headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=45) as response:
        data = response.read(maximum + 1)
    if len(data) > maximum:
        raise ValueError("AppVault response exceeds allowed size")
    return data


def select_release(releases):
    """Only a published, matching first-party rootless artifact is eligible."""
    for release in releases:
        if release.get("draft") or not release.get("published_at"):
            continue
        tag = release.get("tag_name", "")
        for asset in release.get("assets", []):
            match = ASSET.fullmatch(asset.get("name", ""))
            if not match or tag != "v" + match.group(1):
                continue
            name = asset["name"]
            url = f"https://github.com/{SOURCE}/releases/download/{tag}/{name}"
            if asset.get("browser_download_url") != url or asset.get("state") != "uploaded":
                raise ValueError("Unexpected AppVault asset source or state")
            digest = asset.get("digest", "")
            if not re.fullmatch(r"sha256:[0-9a-fA-F]{64}", digest):
                raise ValueError("AppVault release is missing its SHA-256 digest")
            size = asset.get("size")
            if not isinstance(size, int) or not 0 < size <= MAX_BYTES:
                raise ValueError("Invalid AppVault asset size")
            return match.group(1), url, size, digest.split(":", 1)[1].lower()
    raise ValueError("No published AppVault rootless DEB release")


def check_control(blob, expected_version):
    with tempfile.NamedTemporaryFile(suffix=".deb") as file:
        file.write(blob)
        file.flush()
        fields = ["Package", "Version", "Architecture", "Maintainer", "Author"]
        lines = subprocess.check_output(
            ["dpkg-deb", "-f", file.name, *fields], text=True
        ).splitlines()
    actual = {}
    for line in lines:
        key, sep, value = line.partition(":")
        if not sep or key not in fields or key in actual:
            raise ValueError("Malformed AppVault Debian metadata")
        actual[key] = value.strip()
    if set(actual) != set(fields):
        raise ValueError("Incomplete AppVault Debian metadata")
    expected = dict(Package=PACKAGE, Version=expected_version,
                    Architecture="iphoneos-arm64", Maintainer="soum91", Author="soum91")
    if actual != expected:
        raise ValueError(f"Unexpected AppVault package metadata: {actual}")


def run(root=ROOT):
    releases = json.loads(request_bytes(API, 1024 * 1024))
    version, url, size, digest = select_release(releases)
    data = request_bytes(url, MAX_BYTES)
    if len(data) != size or hashlib.sha256(data).hexdigest() != digest:
        raise ValueError("AppVault release size or SHA-256 mismatch")
    check_control(data, version)

    source_path = root / "sileo/sources.json"
    config = json.loads(source_path.read_text())
    if config.get("schema_version") != 1:
        raise ValueError("Unsupported Sileo source manifest")
    current = next((s for s in config["sources"] if s.get("name") == "AppVault"), None)
    if current:
        old = re.search(r"com\.soum91\.appvault_(\d+\.\d+\.\d+)_iphoneos-arm64\.deb$",
                        current.get("local_deb", ""))
        if not old:
            raise ValueError("AppVault manifest points to an unexpected package")
        if subprocess.run(["dpkg", "--compare-versions", version, "lt", old.group(1)],
                          check=False).returncode == 0:
            raise ValueError("Refusing AppVault downgrade")

    filename = f"com.soum91.appvault_{version}_iphoneos-arm64.deb"
    dest = root / "sileo/local" / filename
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and dest.read_bytes() != data:
        raise ValueError("Refusing to replace an existing AppVault version with different bytes")
    if not dest.exists():
        dest.write_bytes(data)

    entry = {"name": "AppVault", "local_deb": f"sileo/local/{filename}",
             "packages": [PACKAGE]}
    if current is None:
        config["sources"].append(entry)
    else:
        current.clear()
        current.update(entry)
    source_path.write_text(json.dumps(config, indent=2) + "\n")
    print(f"AppVault rootless {version}: verified {size} bytes, SHA-256 {digest}")
    print(f"Source: {url}")


if __name__ == "__main__":
    run()
