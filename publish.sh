#!/bin/sh
# Publishes a set of binaries: build, commit dist/, commit the README table,
# tag, push.
#
#   sh publish.sh [YYYYMMDD-N] [-n] [-b branch] [--push]
#
# The tag defaults to today with sequence 1. It is passed into the build as
# PFS_REF before it exists, so every binary names the tag that is created two
# commits later, and the tag ends up on the README commit: checking it out
# reproduces exactly the files it contains, and the download links in the table
# address that tag.
#
# -n prints what would run. Without --push the tag is created and the push is
# left to the caller.

set -eu

TAG=$(date +%Y%m%d)-1
BRANCH=jpu
DRY=
PUSH=

while [ $# -gt 0 ]; do
	case $1 in
	-n) DRY=1 ;;
	--push) PUSH=1 ;;
	-b) shift; BRANCH=$1 ;;
	-*) echo "usage: sh publish.sh [YYYYMMDD-N] [-n] [-b branch] [--push]"; exit 2 ;;
	*) TAG=$1 ;;
	esac
	shift
done

run() {
	echo "+ $*"
	[ -n "$DRY" ] || "$@"
}

die() { echo "ERROR: $*" >&2; exit 1; }

# Refuse rather than repair: a set is only worth publishing if the tree it came
# from is exactly what is committed.
[ "$(git rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] || die "not on $BRANCH"
[ -z "$(git status --porcelain)" ] || die "working tree not clean"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && \
	die "tag $TAG exists, pass the next sequence"
[ -f dist-table.py ] || die "no dist-table.py"
grep -q '<!-- dist-table -->' README.md || die "no dist-table markers in README.md"

echo "== publishing $TAG from $(git rev-parse --short HEAD) on $BRANCH"

run make dist PFS_REF="$TAG"

# The stamp is the only proof that the binaries carry the tag rather than a
# hash, and that nothing stale survived in dist/.
if [ -z "$DRY" ]; then
	n=0
	for f in dist/*/pfs3aio.*; do
		strings -a "$f" | grep -q "\[jpu/$TAG\]" || die "$f does not carry [jpu/$TAG]"
		n=$((n + 1))
	done
	[ "$n" -gt 0 ] || die "dist/ is empty"
	echo "== $n binaries carry [jpu/$TAG]"
fi

run git add dist
run git commit -m "dist: built binaries for $TAG"
run git add README.md
run git commit -m "dist: download table in README"
run git tag "$TAG"

if [ -n "$PUSH" ]; then
	run git push origin "$BRANCH"
	run git push origin "$TAG"
else
	echo "== not pushed; run: git push origin $BRANCH && git push origin $TAG"
fi
