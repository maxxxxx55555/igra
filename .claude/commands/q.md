---
description: Print workqueue state in <=20 lines and name the next item. No prose.
---
Run: awk -F'\t' 'NR>1{c[$7]++} END{for(k in c) printf "%s=%d ", k, c[k]; print ""}' .qa_logs/WORKQUEUE.tsv
Then: the first OPEN row in R14 priority order — print its ID, TASK and ACCEPT (`python .qa_logs/qset.py --q` prints both lines).
Then: `git log --oneline -1` and `git status --porcelain | wc -l`.
At most 20 lines total. Do not explain. Do not summarise the prompt. Do not re-plan.
