---
name: backup-first
description: Before destructive ops (delete/overwrite scenes or scripts) makes a timestamped copy in _BACKUPS.
---
Before deleting or overwriting project files: copy them to _BACKUPS\YYYY-MM-DD_HH-MM\ preserving relative paths via Copy-Item. Skip only if the file is under VCS with a clean commit.