import argparse

from .manifest import load_manifest, validate_manifest


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="pak-corpus-validate")
    ap.add_argument("--manifest", default="manifest.json")
    ap.add_argument("--samples", default="samples")
    a = ap.parse_args(argv)
    errs = validate_manifest(load_manifest(a.manifest), a.samples)
    if errs:
        for e in errs:
            print(f"ERROR: {e}")
        return 1
    print("manifest valid")
    return 0
