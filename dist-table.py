#!/usr/bin/env python3
# Regenerates the download table in README.md from what is in dist/.
#
#   python3 dist-table.py [dist_dir] [readme]
#
# Run by "make dist". Every column comes from the binaries and from tiers.mk,
# never from a second copy of the naming rules: the tag column is the bracket
# sequence read out of the file's own $VER string, so a row cannot describe a
# build that was not published.

import os
import re
import sys

DIST = sys.argv[1] if len(sys.argv) > 1 else "dist"
README = sys.argv[2] if len(sys.argv) > 2 else "README.md"
TIERS_MK = os.environ.get("TIERS_MK", "tiers.mk")

# Group order, and the heading each toolchain gets.
ORDER = ["gcc13", "gcc6", "gcc15", "gcc16", "vbcc"]

BEGIN = "<!-- dist-table -->"
END = "<!-- /dist-table -->"


def tier_field(field, tier):
    pat = re.compile(r"^TIER_%s_%s\s*=\s*(\S+)" % (field, tier), re.M)
    m = pat.search(open(TIERS_MK).read())
    return m.group(1) if m else None


def runs_on(tier):
    lo, hi = tier_field("MINCPU", tier), tier_field("MAXCPU", tier)
    if lo == hi:
        return "%s only" % lo
    return "%s to %s" % (lo, hi)


def brackets(path):
    with open(path, "rb") as f:
        blob = f.read()
    m = re.search(rb"\$VER:[^\x00]*?((?:\[[^\]]*\])+)", blob)
    return m.group(1).decode() if m else None


def cc_of(bracket):
    return bracket[1:].split("/", 1)[0]


def ref_of(bracket):
    # The origin bracket, [<fork>/<tag or commit>], is also the URL ref: a link
    # then serves the set it describes and not whatever came later.
    m = re.search(r"\[[^/\]]+/([^\]]+)\]$", bracket)
    if not m:
        sys.exit("no origin bracket in %s" % bracket)
    return m.group(1)


def heading(cc):
    if cc.startswith("gcc"):
        return "GCC " + cc[3:]
    return cc


def rows():
    out = []
    for tier in sorted(os.listdir(DIST)):
        d = os.path.join(DIST, tier)
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            path = os.path.join(d, name)
            tag = brackets(path)
            if not tag:
                sys.exit("no $VER brackets in %s" % path)
            out.append({
                "tier": tier,
                "tc": name.split(".", 1)[1],
                "file": name,
                "tag": tag,
                "size": os.path.getsize(path),
                "cc": cc_of(tag),
                "ref": ref_of(tag),
            })
    return out


def render(rs):
    groups = {}
    for r in rs:
        groups.setdefault(r["tc"], []).append(r)
    order = [t for t in ORDER if t in groups] + \
            [t for t in sorted(groups) if t not in ORDER]

    lines, refs = [], []
    for tc in order:
        g = sorted(groups[tc], key=lambda r: r["tier"])
        lines += ["## %s" % heading(g[0]["cc"]), ""]
        lines += ["| build | runs on | tag | size | download |", "|---|---|---|---|---|"]
        for r in g:
            ref = "%s-%s" % (tc, r["tier"])
            lines.append("| `%s` | %s | `%s` | %d | [%s][%s] |"
                         % (r["tier"], runs_on(r["tier"]), r["tag"],
                            r["size"], r["file"], ref))
            refs.append("[%s]: https://raw.githubusercontent.com/pulchart/pfs3aio/%s/%s/%s/%s"
                        % (ref, r["ref"], DIST, r["tier"], r["file"]))
        lines.append("")
    return "\n".join(lines + refs)


def main():
    text = open(README).read()
    if BEGIN not in text or END not in text:
        sys.exit("%s has no %s ... %s markers" % (README, BEGIN, END))
    head, rest = text.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    new = head + BEGIN + "\n" + render(rows()) + "\n" + END + tail
    if new != text:
        open(README, "w").write(new)
        print("%s: table updated" % README)
    else:
        print("%s: table already current" % README)


main()
