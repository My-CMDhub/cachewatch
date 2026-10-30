#!/bin/zsh
# Smoke test: runs cachewatch against a fake home folder. Your real caches are never touched.
cd ${0:A:h}

T=$(mktemp -d); hog=""
trap '[[ -n $hog ]] && kill $hog 2>/dev/null; rm -rf $T' EXIT  # however the test ends: stop the fake hog, tidy up
H=$T/home
mkdir -p $T/bin $T/stub $H/.npm $H/.config/cachewatch
swiftc -O src/cachering.swift -o $T/bin/cachering || { print "FAIL  building the ring helper"; exit 1; }
cp bin/cachewatch $T/bin/
print "#!/bin/zsh\nprint -- \"\$@\" >> $T/opened" > $T/stub/open  # records notifications instead of showing them
chmod +x $T/stub/open
print 'GROW_GB=0.002 BG_CHECK=0' > $H/.config/cachewatch/config.zsh  # ~2 MB so tiny files trip it; background check off until its own tests

run() { HOME=$H PATH=$T/stub:$PATH $T/bin/cachewatch "$@"; }
ok() { print "  ok  $1"; }
fail() { print "FAIL  $1"; exit 1; }

mkfile -n 2m $H/.npm/a
run --bar | head -1 | grep -q 'templateImage=' && ok "fresh install shows a grey ring" || fail "fresh install shows a grey ring"
[[ -s $H/Library/Logs/cachewatch.baseline ]] && ok "first run records a baseline" || fail "first run records a baseline"
run --notify; [[ ! -e $T/opened ]] || ! grep -q 'cache%20sweep' $T/opened && ok "no growth, no notification" || fail "no growth, no notification"

mkfile -n 3m $H/.npm/b  # grow 3 MB, past the 2 MB line
run --bar | head -1 | grep -q 'templateImage=' && ok "the menu reuses saved sizes until the next measure" || fail "the menu reuses saved sizes until the next measure"
run --measure
run --bar | head -1 | grep -q ' image=' && ok "growth past GROW_GB turns the ring orange" || fail "growth past GROW_GB turns the ring orange"
run --notify; grep -q 'cache%20sweep' $T/opened && ok "growth past GROW_GB sends a notification" || fail "growth past GROW_GB sends a notification"

run --clean </dev/null | grep -q 'Nothing over 100 MB' && ok "clean skips caches under 100 MB" || fail "clean skips caches under 100 MB"
run --bar | head -1 | grep -q 'templateImage=' && ok "the ring resets after a sweep" || fail "the ring resets after a sweep"
run | grep -q 'npm' && ok "table lists the npm cache" || fail "table lists the npm cache"

# Background check: a stand-in runaway process (`yes` burns a CPU core)
print 'BG_CHECK=1 CPU_HOG=30 HOG_MIN=0' >> $H/.config/cachewatch/config.zsh
yes > /dev/null 2>&1 & hog=$!
command sleep 2
run --bar | grep -q 'yes, ' && fail "a hot process isn't flagged on its first check" || ok "a hot process isn't flagged on its first check"
run --bar | grep -q 'yes, .* CPU' && ok "a process hot on two checks in a row is flagged" || fail "a process hot on two checks in a row is flagged"
run --bar >/dev/null
(( $(grep -c 'Running%20in%20the%20background:%20yes' $T/opened) == 1 )) && ok "it notifies once, not on every refresh" || fail "it notifies once, not on every refresh"
run --fix "cpu:$hog:wrongname"; kill -0 $hog 2>/dev/null && ok "quick fix refuses when the process name doesn't match" || fail "quick fix refuses when the process name doesn't match"
run --fix "cpu:$hog:yes"; command sleep 1; kill -0 $hog 2>/dev/null && fail "quick fix stops the process" || ok "quick fix stops the process"
print "All good."
