#!/bin/sh
# Publishes a set of binaries: build, stage the GitHub release, tag, push.
#
#   sh publish.sh [YYYYMMDD-N] [-n] [-b branch] [--push] [-- make-args]
#
# The tag defaults to today with sequence 1. It is passed into the build as
# PFS_REF before it exists, so every binary names the tag that is then created
# on the commit it was built from. The binaries are not committed:
# release-table.py stages them as release assets in release/<tag>/ and prints
# the gh command that creates the draft.
#
# Arguments after "--" go to make, to build part of the set:
#   sh publish.sh 20260920-1 -- TIERS="68080" INSTALL_TOOLCHAINS=gcc6
# Binaries left in dist/ from an earlier tag stay in the table and link to
# that tag's release.
#
# -n prints what would run. --push pushes the branch and the tag; the draft
# is never created here.

set -eu

die() { echo "ERROR: $*" >&2; exit 1; }

TAG=$(date +%Y%m%d)-1
BRANCH=jpu
DRY=
PUSH=

while [ $# -gt 0 ]; do
	case $1 in
	-n) DRY=1 ;;
	--push) PUSH=1 ;;
	-b) [ $# -ge 2 ] || die "-b needs a branch"; shift; BRANCH=$1 ;;
	--) shift; break ;;
	-*) echo "usage: sh publish.sh [YYYYMMDD-N] [-n] [-b branch] [--push] [-- make-args]"; exit 2 ;;
	*) TAG=$1 ;;
	esac
	shift
done

run() {
	echo "+ $*"
	[ -n "$DRY" ] || "$@"
}

# Refuse rather than repair: a set is only worth publishing if the tree it came
# from is exactly what is committed.
[ "$(git rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] || die "not on $BRANCH"
[ -z "$(git status --porcelain)" ] || die "working tree not clean"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && \
	die "tag $TAG exists, pass the next sequence"
[ -f release-table.py ] || die "no release-table.py"
[ -f "release-notes/$TAG.md" ] || die "no release-notes/$TAG.md"

echo "== publishing $TAG from $(git rev-parse --short HEAD) on $BRANCH"

run make dist PFS_REF="$TAG" "$@"

# Stages the binaries stamped with the tag and refuses a stamp that is neither
# the tag nor an existing one. Runs before the tag exists so a refusal leaves
# nothing behind.
run python3 release-table.py "$TAG"

run git tag "$TAG"

if [ -n "$PUSH" ]; then
	run git push origin "$BRANCH"
	run git push origin "$TAG"
else
	echo "== not pushed; run: git push origin $BRANCH && git push origin $TAG"
fi
