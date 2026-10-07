#!/usr/bin/env python3
"""Exhaustive-ish list of BlueprintCallable UFUNCTIONs Chiv2 exposes, parsed from C++ headers,
with the DevelopmentOnly flag resolved (dev-only nodes are stripped from Shipping, like Print
String) and dangerous capabilities flagged.

Why headers: UE 4.25's in-editor Python can't walk function metadata/classes (verified), and the
palette commandlet drops the DevelopmentOnly flag. The flag lives in the UFUNCTION() macro in the
headers, so we parse those directly. Covers classes whose headers we have (ArgonSDK/Source = the
Chiv2 'TBL' module a modder sees, + engine Kismet/Gameplay). Does NOT cover closed binary-only
plugins with no headers — documented limitation.

Usage: python extract_bp_callable.py <header-root> [<header-root> ...] -o out.json
Each root is scanned recursively for *.h.
Output JSON: {summary, functions:[{class,function,owner_header,specifiers,dev_only,dangerous,why}]}
"""
import argparse
import json
import os
import re

# Dangerous-capability patterns (lowercased substring on function name or specifiers/category).
DANGER = [
    "launchurl", "launchexternalurl", "browsetourl", "openurl", "geturl", "loadurl",
    "savestringtofile", "loadfiletostring", "savetext", "writefile", "readfile", "deletefile",
    "savegametoslot", "loadgamefromslot",
    "httprequest", "processrequest", "downloadimage", "download",
    "executeconsolecommand", "consolecommand", "execcommand", "exec(",
    "createproc", "launchprocess", "runprocess", "spawnprocess", "openprocess",
    "socket", "sendto", "analytics", "telemetry", "webwidget", "webbrowser",
]

# function name = first identifier directly before '(' on the signature line.
SIG_NAME_RE = re.compile(r"([A-Za-z_]\w*)\s*\(")


def _ufunction_specs(text):
    """Yield (spec_string, index_after_macro) for each UFUNCTION(...), balancing nested parens
    so meta=(...) inside the macro doesn't truncate the spec."""
    i = 0
    while True:
        k = text.find("UFUNCTION", i)
        if k == -1:
            return
        p = text.find("(", k)
        if p == -1:
            return
        depth = 0
        j = p
        while j < len(text):
            c = text[j]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        yield text[p + 1:j], j + 1
        i = j + 1


def parse_header(path, text):
    out = []
    for spec, after in _ufunction_specs(text):
        if "blueprintcallable" not in spec.lower():
            continue
        # The signature is the next non-empty, non-comment line after the macro.
        tail = text[after:]
        sig = None
        for line in tail.splitlines():
            s = line.strip()
            if not s or s.startswith("//") or s.startswith("/*") or s.startswith("*"):
                continue
            sig = s
            break
        if not sig:
            continue
        nm = SIG_NAME_RE.search(sig)
        if not nm:
            continue
        fname = nm.group(1)
        if fname in ("UFUNCTION", "GENERATED_BODY"):
            continue
        spec_l = spec.lower()
        name_l = fname.lower()
        dev_only = "developmentonly" in spec_l
        why = sorted({p for p in DANGER if p in name_l or p in spec_l})
        out.append({
            "function": fname,
            "owner_header": os.path.basename(path),
            "specifiers": " ".join(spec.split()),
            "dev_only": dev_only,
            "dangerous": bool(why),
            "why": ",".join(why),
        })
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("roots", nargs="+")
    ap.add_argument("-o", "--out", required=True)
    a = ap.parse_args()

    funcs = []
    for root in a.roots:
        for dirpath, _dirs, files in os.walk(root):
            for fn in files:
                if not fn.endswith(".h"):
                    continue
                p = os.path.join(dirpath, fn)
                try:
                    with open(p, "r", encoding="utf-8", errors="replace") as f:
                        funcs.extend(parse_header(p, f.read()))
                except OSError:
                    continue

    summary = {
        "blueprint_callable_total": len(funcs),
        "dev_only_total": sum(1 for f in funcs if f["dev_only"]),
        "dangerous_total": sum(1 for f in funcs if f["dangerous"]),
        "dangerous_shipping": sum(1 for f in funcs if f["dangerous"] and not f["dev_only"]),
        "dangerous_dev_only": sum(1 for f in funcs if f["dangerous"] and f["dev_only"]),
    }
    funcs.sort(key=lambda f: (not f["dangerous"], f["dev_only"], f["owner_header"], f["function"]))
    with open(a.out, "w", encoding="utf-8") as f:
        json.dump({"summary": summary, "functions": funcs}, f, indent=1)
    print("wrote", a.out)
    print(json.dumps(summary, indent=1))


if __name__ == "__main__":
    main()
