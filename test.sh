#!/bin/zsh
# Smoke test: runs cachewatch against a fake home folder. Your real caches are never touched.
set -e
cd ${0:A:h}

T=$(mktemp -d); trap "rm -rf $T" EXIT
H=$T/home
mkdir -p $T/bin $T/stub $H/.npm $H/.config/cachewatch
swiftc -O src/cachering.swift -o $T/bin/cachering
cp bin/cachewatch $T/bin/
print "#!/bin/zsh\nprint -- \"\$@\" >> $T/opened" > $T/stub/open  # records notifications instead of showing them
chmod +x $T/stub/open
print 'GROW_GB=0.002' > $H/.config/cachewatch/config.zsh  # about 2 MB, so tiny files can trip it

run() { HOME=$H PATH=$T/stub:$PATH $T/bin/cachewatch "$@"; }
ok() { print "  ok  $1"; }
fail() { print "FAIL  $1"; exit 1; }

mkfile -n 2m $H/.npm/a
run --bar | head -1 | grep -q 'templateImage=' && ok "fresh install shows a grey ring" || fail "fresh install shows a grey ring"
[[ -s $H/Library/Logs/cachewatch.baseline ]] && ok "first run records a baseline" || fail "first run records a baseline"
run --notify; [[ ! -e $T/opened ]] || ! grep -q notify $T/opened && ok "no growth, no notification" || fail "no growth, no notification"

mkfile -n 3m $H/.npm/b  # grow 3 MB, past the 2 MB line
run --bar | head -1 | grep -q ' image=' && ok "growth past GROW_GB turns the ring orange" || fail "growth past GROW_GB turns the ring orange"
run --notify; grep -q 'swiftbar://notify' $T/opened && ok "growth past GROW_GB sends a notification" || fail "growth past GROW_GB sends a notification"

run --clean </dev/null | grep -q 'Nothing over 100 MB' && ok "clean skips caches under 100 MB" || fail "clean skips caches under 100 MB"
run --bar | head -1 | grep -q 'templateImage=' && ok "the ring resets after a sweep" || fail "the ring resets after a sweep"
run | grep -q 'npm' && ok "table lists the npm cache" || fail "table lists the npm cache"
print "All good."
