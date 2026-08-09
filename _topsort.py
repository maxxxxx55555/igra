import re, os

AL = []
for line in open("project.godot", encoding="utf-8"):
    m = re.match(r'^(\w+)="\*res://(.+?\.gd)"', line.strip())
    if m:
        AL.append((m.group(1), "res://" + m.group(2)))

names = [n for n, _ in AL]
edges = []
for n, path in AL:
    p = path.replace("res://", "")
    if not os.path.exists(p):
        print("MISSING:", path)
        continue
    text = open(p, encoding="utf-8", errors="replace").read()
    for other in names:
        if other == n:
            continue
        if re.search(r'\b' + other + r'\b', text):
            edges.append(f"{n} -> {other}")

for e in sorted(set(edges)):
    print(e)

print("---")
# topological sort
import collections
idx = {n: i for i, n in enumerate(names)}
suffix = []
def refs_of(n, path):
    text = open(path.replace("res://", ""), encoding="utf-8", errors="replace").read()
    return [o for o in names if o != n and re.search(r'\b' + o + r'\b', text)]
order = []
seen = set()
def visit(n):
    if n in seen: return
    seen.add(n)
    path = dict(AL)[n]
    for o in refs_of(n):
        visit(o)
    order.append(n)
for n in names:
    visit(n)
for i, n in enumerate(order):
    print(f"{i+1}\t{n}")