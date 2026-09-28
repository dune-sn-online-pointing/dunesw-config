#!/usr/bin/env python3
"""
Check completeness of generated tpstreams for a range of cats and emit a
resubmission args file for gen_wave.sh --args-file.

Looks in BOTH places a file can be:
  1. staging:  /eos/project-e/ep-nu/public/snop-simulations/directions/
       prodmarley_nue_{es|cc}_gkvm_dune10kt_1x2x2_customDirection_cat{N}-
       triggerana_tree_1x2x2_simpleThr_production-40events/{i}_tpstream.root
  2. final:    /eos/project-e/ep-nu/evilla/sn-online-pointing/sn-burst-samples/
       cat{N:06d}/tpstreams/{es|cc}_{i:06d}_tpstream.root

Usage: check_gen.py --first 623 --last 1223 [--resubmit-args FILE]
"""
import argparse
from pathlib import Path

STAGING = Path("/eos/project-e/ep-nu/public/snop-simulations/directions")
FINAL = Path("/eos/project-e/ep-nu/evilla/sn-online-pointing/sn-burst-samples")
HOME_DIR = "/afs/cern.ch/work/e/evilla/private/dune/dunesw/dunesw-config"
JSON_SETTINGS = f"{HOME_DIR}/json/v10_10_05d00.json"
RECO = "triggerana_tree_1x2x2_simpleThr_production"
N_EVENTS = 40
EXPECTED = {"es": 10, "cc": 100}


def staging_dir(itype, cat):
    return STAGING / (
        f"prodmarley_nue_{itype}_gkvm_dune10kt_1x2x2_customDirection_cat{cat}-{RECO}-{N_EVENTS}events"
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--first", type=int, required=True)
    ap.add_argument("--last", type=int, required=True)
    ap.add_argument("--resubmit-args", default=None)
    args = ap.parse_args()

    missing = []  # (cat, itype, i)
    n_done = 0
    incomplete_cats = 0
    for cat in range(args.first, args.last + 1):
        cat_missing = []
        for itype, n_files in EXPECTED.items():
            sdir = staging_dir(itype, cat)
            fdir = FINAL / f"cat{cat:06d}" / "tpstreams"
            for i in range(n_files):
                spath = sdir / f"{i}_tpstream.root"
                fpath = fdir / f"{itype}_{i:06d}_tpstream.root"
                ok = (fpath.exists() and fpath.stat().st_size > 0) or (
                    spath.exists() and spath.stat().st_size > 0
                )
                if ok:
                    n_done += 1
                else:
                    cat_missing.append((cat, itype, i))
        if cat_missing:
            incomplete_cats += 1
            if len(cat_missing) <= 6:
                detail = ", ".join(f"{t}_{i}" for _, t, i in cat_missing)
            else:
                detail = f"{len(cat_missing)} files"
            print(f"cat{cat:06d}: missing {detail}")
        missing.extend(cat_missing)

    total = (args.last - args.first + 1) * 110
    print(f"\nDone {n_done}/{total} files; {incomplete_cats} incomplete cats; {len(missing)} missing files")

    if args.resubmit_args and missing:
        out = Path(args.resubmit_args)
        with out.open("w") as fh:
            for cat, itype, i in missing:
                fcl = f"prodmarley_nue_{itype}_gkvm_dune10kt_1x2x2"
                fh.write(
                    f"-j {JSON_SETTINGS} --home-config {HOME_DIR} --delete-root true "
                    f"-m {fcl} --catalog-direction {cat} -g -d -r -n {N_EVENTS} -f {i}\n"
                )
        print(f"Wrote resubmission args: {out} ({len(missing)} jobs)")


if __name__ == "__main__":
    main()
