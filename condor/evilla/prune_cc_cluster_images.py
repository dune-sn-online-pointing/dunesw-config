#!/usr/bin/env python3
"""
Prune CC cluster images (cc_*.npz) from burst-sample cats to free EOS inodes.
User-approved 2026-08-28: CC cluster images are not used at training; volume
images and ES cluster images are KEPT everywhere.

Eligibility per cat (never touch a cat the pipeline may still need as input):
  - TRAINING_CAT.txt present (cats 400-621): always eligible (never evaluated)
  - otherwise: eligible only once scenario_cos_theta_report.json exists for the
    cat in one of the pipeline output bases (final = cats 1-399,
    ext1000 = cats 623-1223)

Idempotent + re-runnable: safe to invoke again as new pipeline reports land.

Usage: prune_cc_cluster_images.py --first 1 --last 1223 [--execute]  (default dry-run)
"""
import argparse
from pathlib import Path

BASE = Path("/eos/project-e/ep-nu/evilla/sn-online-pointing/sn-burst-samples")
COND = "tick3_ch2_min2_tot3_e3p0"
REPORT_BASES = [
    Path("/eos/user/e/evilla/dune/sn-tps/condor_scenarios_v80t080_final"),
    Path("/eos/user/e/evilla/dune/sn-tps/condor_scenarios_v80t080_ext1000"),
]


def eligible(cat: str, d: Path) -> bool:
    if (d / "TRAINING_CAT.txt").is_file():
        return True
    return any((rb / cat / "scenario_cos_theta_report.json").is_file()
               for rb in REPORT_BASES)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--first", type=int, required=True)
    ap.add_argument("--last", type=int, required=True)
    ap.add_argument("--execute", action="store_true")
    args = ap.parse_args()

    tot_files = tot_cats = skipped = 0
    for n in range(args.first, args.last + 1):
        cat = f"cat{n:06d}"
        d = BASE / cat
        if not d.is_dir():
            continue
        ci = d / f"{cat}_cluster_images_{COND}"
        if not ci.is_dir():
            continue
        if not eligible(cat, d):
            skipped += 1
            continue
        n_del = 0
        for plane in ("X", "U", "V"):
            pd = ci / plane
            if not pd.is_dir():
                continue
            for f in pd.glob("cc_*.npz"):
                n_del += 1
                if args.execute:
                    try:
                        f.unlink()
                    except OSError as e:
                        print(f"warn {f}: {e}")
        if n_del:
            tot_cats += 1
            tot_files += n_del
            if tot_cats % 50 == 0:
                print(f"...{tot_cats} cats, {tot_files} files (at {cat})",
                      flush=True)
    mode = "DELETED" if args.execute else "would delete"
    print(f"{mode} {tot_files} cc cluster-image files across {tot_cats} cats "
          f"({args.first}-{args.last}); {skipped} cats skipped (no report yet)")


if __name__ == "__main__":
    main()
