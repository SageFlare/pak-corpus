import json
import re
import os

STATES = {"benign", "flagged-latent", "flagged-active"}
VECTORS = {"asset_replacement", "launch_url", "web_widget", "benign"}
_REQUIRED = {"name", "vector", "intent", "expected_state", "notes"}
_ABS = re.compile(r"[A-Za-z]:\\|/Users/|/home/")


def load_manifest(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def validate_manifest(manifest, samples_dir):
    errors = []
    for i, e in enumerate(manifest):
        missing = _REQUIRED - set(e)
        if missing:
            errors.append(f"entry {i}: missing fields {sorted(missing)}")
            continue
        if e["expected_state"] not in STATES:
            errors.append(f"{e['name']}: bad expected_state {e['expected_state']!r}")
        if e["vector"] not in VECTORS:
            errors.append(f"{e['name']}: bad vector {e['vector']!r}")
        pak = os.path.join(samples_dir, f"{e['name']}.pak")
        if not os.path.exists(pak):
            errors.append(f"{e['name']}: sample pak not found ({e['name']}.pak)")
        for k, v in e.items():
            if isinstance(v, str) and _ABS.search(v):
                errors.append(f"{e['name']}: field {k} contains an absolute/user path")
    return errors
