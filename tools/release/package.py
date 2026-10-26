"""Create one self-contained PowerShell with the exact, verified Git delta."""
import argparse
import base64
import hashlib
from pathlib import Path
import subprocess
import tempfile

BASE = "a4b1943d1d6fbcee4eeffeff795b0a959fdb8dea"
ROOT = Path(__file__).resolve().parents[2]


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], stderr=subprocess.STDOUT).decode().strip()


def package(target):
    if git("status", "--porcelain"):
        raise RuntimeError("Commit all sources and evidence before packaging")
    head = git("rev-parse", "HEAD")
    git("merge-base", "--is-ancestor", BASE, head)
    if git("for-each-ref", "--format=%(refname)", "refs/heads/release-payload"):
        raise RuntimeError("Unexpected payload reference")
    # Own temporary ref only; this cannot update main or a remote.
    git("update-ref", "refs/heads/release-payload", head)
    try:
        with tempfile.TemporaryDirectory(prefix="igra-package-") as directory:
            bundle = Path(directory) / "source.bundle"
            git("bundle", "create", str(bundle), "refs/heads/release-payload", "^" + BASE)
            git("bundle", "verify", str(bundle))
            data = bundle.read_bytes()
    finally:
        git("update-ref", "-d", "refs/heads/release-payload", head)
    encoded = base64.b64encode(data).decode("ascii")
    wrapped = "\n".join(encoded[i:i + 100] for i in range(0, len(encoded), 100))
    template = (ROOT / "tools/release/MegaRelease.ps1.in").read_text(encoding="utf-8")
    text = template.replace("@@HEAD@@", head).replace("@@SHA256@@", hashlib.sha256(data).hexdigest()).replace("@@BUNDLE@@", wrapped)
    target = Path(target).resolve()
    target.parent.mkdir(parents=True, exist_ok=True)
    # BOM is required for Russian console strings in Windows PowerShell 5.1.
    target.write_bytes(b"\xef\xbb\xbf" + text.replace("\n", "\r\n").encode("utf-8"))
    print(f"{target}\nhead={head}\nbytes={target.stat().st_size}\nsha256={hashlib.sha256(target.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output")
    package(parser.parse_args().output)
