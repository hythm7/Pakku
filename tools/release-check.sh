#!/usr/bin/env bash
#
# The end-to-end pass before a release: installs this tree into a scratch repo and drives the
# installed pakku through real commands against fez and REA. The unit tests do not do that.
#
#   tools/release-check.sh [--update] [raku]
#
#   raku      the raku to use (default: the one on PATH); run it once per Rakudo you care about
#   --update  also update a Pakku from the chou tarball to the newest release and check that the
#             new one is still there afterwards. Only meaningful with a raku that has no Pakku
#             in its own repos: an installed one answers the update instead.
#
# Needs the network. Touches nothing but a temporary directory, and ~/.pakku (index and cache).
# Exits 0 when every check passed.

UPDATE=''
[ "$1" = '--update' ] && { UPDATE=1; shift; }

RAKU=$(command -v "${1:-raku}") || { echo "no such raku: ${1:-raku}"; exit 2; }
SRC=$(cd "$(dirname "$0")/.." && pwd)
W=$(mktemp -d "${TMPDIR:-/tmp}/pakku-release-check.XXXXXX")
REPO="$W/repo"

trap 'rm -rf "$W"' EXIT

mkdir "$W/cwd" && cd "$W/cwd" || exit 2

echo "== $("$RAKU" -e 'print $*RAKU.compiler.version') at $RAKU"

"$RAKU" -I"$SRC" "$SRC/bin/pakku" nopretty nobar nospinner add notest to "$REPO" "$SRC" > "$W/install.log" 2>&1 \
  || { echo "FAIL installing this tree"; tail -5 "$W/install.log"; exit 1; }

export RAKULIB="inst#$REPO"
export PATH="$(dirname "$RAKU"):$PATH"

P="$REPO/bin/pakku nopretty nobar nospinner"
n=0; bad=0

# t <expected exit code> <pakku arguments...> : the exit code, and no stack trace or compiler warning in the output
t() {
  local want=$1; shift; n=$((n+1))
  local out rc crash
  out=$($P "$@" 2>&1); rc=$?
  crash=$(echo "$out" | grep -c -E '^ *in (block|method|sub|regex|any) |===SORRY|lang-call|Use of Nil|Use of uninitialized|No such method|Cannot (resolve|unbox|find)|Type check failed')
  if [ $rc -ne "$want" ] || [ "$crash" -ne 0 ]; then
    bad=$((bad+1)); echo "FAIL rc=$rc want=$want :: pakku $*"; echo "$out" | sed 's/^/     | /' | tail -6
  else
    echo "ok   rc=$rc :: pakku $*"
  fi
}

t 0 help
t 0 help add
t 0 config
t 0 config recman
t 0 refresh

t 0 search Pakku
t 0 search 'Pakku:ver<chou>'
t 0 search "Pakku:ver('chou')"
t 0 search 'JSON::Fast:ver(* > 0.17):auth<zef:timo>'
t 0 search nolatest JSON::Fast
t 0 search details rak
t 0 search norelaxed JSON::Fast
t 0 info rak
t 0 info 'JSON::Fast:auth<zef:timo>'
t 0 info No::Such::Dist::At::All                 # says not found, and is no failure

t 0 add notest to "$REPO" JSON::Fast
t 0 add to "$REPO" 'JSON::Tiny:ver<1.0+>'                                      # with its tests
t 0 add notest to "$REPO" Hash::Merge                                         # lives in REA only
t 0 add notest nodeps to "$REPO" 'Terminal::ANSIColor:ver(v0.9..*)'
t 0 add notest deps only to "$REPO" 'JSON::Class:auth<zef:jonathanstowe>'
t 0 add notest to "$REPO" https://github.com/moritz/json.git

t 0 list
t 0 list JSON::Fast
t 0 list details JSON::Fast
t 0 list repo "$REPO"
t 0 state
t 0 download JSON::Fast
t 0 test JSON::Tiny
t 0 build JSON::Fast
t 0 dont update
t 0 remove from "$REPO" JSON::Tiny

t 0 force add notest to "$REPO" "$SRC"           # the installed pakku adds itself again
t 0 list Pakku

t 1 add to "$REPO" No::Such::Dist::At::All
t 1 search 'Pakku:ver(chou)'                      # ( ) is code, chou is no routine
t 1 nosuchcommand
t 1 add 'Foo:ver<1'

if [ -n "$UPDATE" ]; then

  # the chou tarball by its address: Pakku:ver<chou> would be the newest chou.N
  U="$W/update-repo"; export RAKULIB="inst#$U"

  "$RAKU" -I"$SRC" "$SRC/bin/pakku" nopretty nobar nospinner add notest to "$U" \
    https://360.zef.pm/P/AK/PAKKU/3b22221d5a45f40311739b79198c0ec2b8f8bac2.tar.gz > "$W/update-install.log" 2>&1

  P="$RAKU -I$SRC $SRC/bin/pakku nopretty nobar nospinner"

  t 0 update notest in "$U" Pakku

  n=$((n+1)); left=$($P list repo "$U" 2>&1 | grep 'Pakku:ver<')

  if [ "$(echo "$left" | grep -c 'Pakku:ver<chou\.[0-9]')" -eq 1 ] && [ "$(echo "$left" | grep -c .)" -eq 1 ]; then
    echo "ok   after the update: $left"
  else
    bad=$((bad+1)); echo "FAIL after the update, the repo holds: ${left:-no Pakku}"
  fi

fi

echo "== $n checks, $bad failed"

[ "$bad" -eq 0 ]
