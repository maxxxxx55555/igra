import os, sys
p = ".qa_logs/WORKQUEUE.tsv"
if os.path.exists(p):
    rows = [l.split("\t") for l in open(p, encoding="utf-8").read().splitlines()[1:] if l.strip()]
    doing = [r[0] for r in rows if len(r) > 6 and r[6].strip() == "DOING"]
    if doing:
        print("Queue item(s) %s left in DOING. Set PASS/FAIL/SKIP/DEFER with evidence before "
              "stopping, or the owner cannot resume cleanly." % ",".join(doing), file=sys.stderr)
        sys.exit(2)
sys.exit(0)
