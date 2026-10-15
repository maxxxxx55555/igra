# The size of the repository's history for the K-1 row (CORRECTION_LOG 258): the sum of the sizes, uncompressed and on disk, of every object reachable from any ref (git rev-list --objects --all piped into git cat-file --batch-check), the count of objects, and the sizes git itself counts.
import collections
import pathlib
import subprocess

ROOT = pathlib.Path("C:/Users/Maxsim/Desktop/TLS_Build/THE_LAST_STREETLIGHT")
rev = subprocess.run(["git", "rev-list", "--objects", "--all"], cwd=ROOT, capture_output=True, text=True).stdout
names = chr(10).join(line.split(" ", 1)[0] for line in rev.splitlines()) + chr(10)
chk = subprocess.run(["git", "cat-file", "--batch-check=%(objecttype) %(objectsize) %(objectsize:disk)"], cwd=ROOT, input=names, capture_output=True, text=True)
total = collections.Counter()
count = collections.Counter()
on_disk = collections.Counter()
missing = 0
for line in chk.stdout.splitlines():
    parts = line.split()
    if len(parts) != 3 or not parts[1].isdigit() or not parts[2].isdigit():
        missing += 1
        continue
    kind, size, disk = parts
    total[kind] += int(size)
    on_disk[kind] += int(disk)
    count[kind] += 1
mib = 1048576
print("reachable objects: %.1f MiB in %d objects (blobs %.1f MiB in %d, trees %.1f MiB, commits %.1f MiB)" % (sum(total.values()) / mib, sum(count.values()), total["blob"] / mib, count["blob"], total["tree"] / mib, total["commit"] / mib))
print("reachable objects on disk (compressed, as git stores them): %.1f MiB (blobs %.1f MiB)" % (sum(on_disk.values()) / mib, on_disk["blob"] / mib))
print("lines without a size (missing objects): %d" % missing)
print(subprocess.run(["git", "count-objects", "-vH"], cwd=ROOT, capture_output=True, text=True).stdout.replace("\n", "; "))
git_dir = ROOT / ".git"
print(".git on disk: %.0f MiB" % (sum(f.stat().st_size for f in git_dir.rglob("*") if f.is_file()) / mib))
