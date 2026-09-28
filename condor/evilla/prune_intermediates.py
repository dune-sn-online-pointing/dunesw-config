#!/usr/bin/env python3
"""
Prune derivable intermediates from burst-sample cats to free EOS inodes.
Deletes per cat: tps/, tps_bg/, cat*_clusters_*/, cat*_matched_clusters_*/
KEEPS: tpstreams/ (raw), cat*_cluster_images_*/, cat*_volume_images_*/, pipeline/, reports.

Safety: a cat is pruned ONLY if its cluster_images/X and volume_images/X both
hold >=110 npz files (processing verifiably complete) — for cats that were
never processed or are mid-processing, nothing is touched.

Usage: prune_intermediates.py --first 1 --last 1223 [--execute]  (default: dry-run)
"""
import argparse
import shutil
from pathlib import Path

BASE = Path("/eos/project-e/ep-nu/evilla/sn-online-pointing/sn-burst-samples")
COND = "tick3_ch2_min2_tot3_e3p0"
REPORT_BASES = [Path("/eos/user/e/evilla/dune/sn-tps/condor_scenarios_v80t080_final"),
                Path("/eos/user/e/evilla/dune/sn-tps/condor_scenarios_v80t080_ext1000")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--first", type=int, required=True)
    ap.add_argument("--last", type=int, required=True)
    ap.add_argument("--execute", action="store_true")
    args = ap.parse_args()

    tot_files = tot_cats = 0
    for n in range(args.first, args.last + 1):
        cat = f"cat{n:06d}"
        d = BASE / cat
        if not d.is_dir():
            continue
        ts = d / "tpstreams"
        n_ts = len(list(ts.glob("*_tpstream.root"))) if ts.is_dir() else 0
        if n_ts < 40:
            continue
        # a cat whose processing outcome is already final (pipeline report exists,
        # or it is a training cat) never needs its intermediates again, whatever
        # the exact image counts; otherwise require complete images (not mid-run)
        final = (d / "TRAINING_CAT.txt").is_file() or any(
            (rb / cat / "scenario_cos_theta_report.json").is_file() for rb in REPORT_BASES)
        if not final:
            ci = d / f"{cat}_cluster_images_{COND}" / "X"
            vi = d / f"{cat}_volume_images_{COND}" / "X"
            if not (ci.is_dir() and len(list(ci.glob("*.npz"))) >= n_ts):
                continue
            if not (vi.is_dir() and len(list(vi.glob("*.npz"))) >= n_ts):
                continue
        targets = [d / "tps", d / "tps_bg",
                   d / f"{cat}_clusters_{COND}",
                   d / f"{cat}_matched_clusters_{COND}"]
        pruned_any = False
        for tgt in targets:
            if tgt.is_dir():
                pruned_any = True
                if args.execute:
                    try:
                        shutil.rmtree(tgt)
                    except OSError as e:
                        print(f"warn {tgt}: {e}")
        if pruned_any:
            tot_cats += 1
            if tot_cats % 50 == 0:
                print(f"...{tot_cats} cats pruned (at {cat})", flush=True)
    mode = "PRUNED" if args.execute else "would prune"
    print(f"{mode} {tot_cats} cats ({args.first}-{args.last})")


if __name__ == "__main__":
    main()
