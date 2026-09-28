#!/usr/bin/env python3
"""
Move freshly generated tpstream files from the staging area
  /eos/project-e/ep-nu/public/snop-simulations/directions/
into the burst-sample catalog layout used by the analysis jsons:
  /eos/project-e/ep-nu/evilla/sn-online-pointing/sn-burst-samples/cat{N:06d}/tpstreams/{es|cc}_{i:06d}_tpstream.root

Adapted from scripts/move_and_rename_tpstream.py (old dest was public/sn-pointing).
Only touches cats in [--first, --last]; never overwrites existing files.
--cleanup additionally removes the per-job intermediate folders
(.../v10_10_05d00/directions/*cat{N}-*_{i}/) and empty staging dirs after moving.

Usage: move_new_cats.py --first 623 --last 1223 [--cleanup] [--dry-run]
"""
import argparse
import re
import shutil
from pathlib import Path

STAGING = Path("/eos/project-e/ep-nu/public/snop-simulations/directions")
INTERMEDIATE = Path("/eos/project-e/ep-nu/public/snop-simulations/v10_10_05d00/directions")
DEST = Path("/eos/project-e/ep-nu/evilla/sn-online-pointing/sn-burst-samples")
DIR_RE = re.compile(
    r"prodmarley_nue_(es|cc)_gkvm_dune10kt_1x2x2_customDirection_cat(\d+)-"
)
FILE_RE = re.compile(r"(\d+)_tpstream\.root$")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--first", type=int, required=True)
    ap.add_argument("--last", type=int, required=True)
    ap.add_argument("--cleanup", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    moved = skipped = 0
    if not STAGING.is_dir():
        print(f"No staging dir {STAGING}")
        return

    for d in sorted(STAGING.iterdir()):
        if not d.is_dir():
            continue
        m = DIR_RE.match(d.name)
        if not m:
            continue
        itype, cat = m.group(1), int(m.group(2))
        if not (args.first <= cat <= args.last):
            continue
        dest_dir = DEST / f"cat{cat:06d}" / "tpstreams"
        for f in sorted(d.iterdir()):
            fm = FILE_RE.match(f.name)
            if not fm:
                continue
            i = int(fm.group(1))
            dest = dest_dir / f"{itype}_{i:06d}_tpstream.root"
            if dest.exists():
                skipped += 1
                continue
            if args.dry_run:
                print(f"would move {f} -> {dest}")
                moved += 1
                continue
            dest_dir.mkdir(parents=True, exist_ok=True)
            shutil.move(str(f), str(dest))
            moved += 1
        # remove staging dir if emptied
        if args.cleanup and not args.dry_run:
            try:
                remaining = [p for p in d.iterdir() if FILE_RE.match(p.name)]
                if not remaining:
                    shutil.rmtree(d)
            except OSError as e:
                print(f"cleanup warning for {d}: {e}")

    print(f"Moved {moved}, skipped-existing {skipped}")

    if args.cleanup and INTERMEDIATE.is_dir():
        removed = 0
        for d in sorted(INTERMEDIATE.iterdir()):
            m = DIR_RE.match(d.name)
            if not m:
                continue
            cat = int(m.group(2))
            if not (args.first <= cat <= args.last):
                continue
            if args.dry_run:
                removed += 1
                continue
            try:
                shutil.rmtree(d)
                removed += 1
            except OSError as e:
                print(f"cleanup warning for {d}: {e}")
        print(f"Removed {removed} intermediate job dirs{' (dry-run)' if args.dry_run else ''}")


if __name__ == "__main__":
    main()
