#!/bin/zsh
# cachewatch installer. Safe to run again: it updates in place and keeps your settings.
# usage: ./install.sh        (shows what it will do, then asks)
#        ./install.sh -y     (no question)
set -e
cd ${0:A:h}

BIN=$HOME/.local/bin
LABEL=io.github.my-cmdhub.cachewatch
PLIST=$HOME/Library/LaunchAgents/$LABEL.plist
CONFIG=$HOME/.config/cachewatch/config.zsh
PLUGINS=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || print $HOME/.config/swiftbar)
PLUGINS=${PLUGINS/#\~/$HOME}

stop() { print "\n$1"; exit 1; }
[[ $(uname) == Darwin ]] || stop "cachewatch only runs on macOS."
(( $(sw_vers -productVersion | cut -d. -f1) >= 13 )) || stop "cachewatch needs macOS 13 Ventura or newer."
command -v swiftc >/dev/null ||
  stop "cachewatch builds two tiny helpers with Apple's Command Line Tools, which aren't installed.
Run this, follow the prompt, then run ./install.sh again:

    xcode-select --install"

swiftbar=1; open -Ra SwiftBar 2>/dev/null || swiftbar=0
brew=1; command -v brew >/dev/null || brew=0

print "
cachewatch $(sed -n 's/^VERSION=//p' bin/cachewatch) will:

  1. Build 2 small helpers from the Swift source in src/ (about 30 seconds)
  2. Put 3 files in ~/.local/bin: cachewatch, cachering, cacheguide
  3. Add its menu-bar plugin to ${PLUGINS/#$HOME/~}
  4. Schedule a weekly check, Sundays at 10:00 (~/Library/LaunchAgents/$LABEL.plist)
  5. Create your settings file ~/.config/cachewatch/config.zsh (yours is kept if it exists)"
(( swiftbar )) || { (( brew )) && print "  6. Install SwiftBar, the free open-source app that shows the ring (brew install --cask swiftbar)"; }
print "
It never deletes anything on its own. Caches are only cleared when you
click Clean now… and answer y for each one. Uninstall any time: ./uninstall.sh
"
[[ $1 == -y ]] || { read -q "?Go ahead? [y/N] " || stop "Nothing changed."; print; }

print "\n→ Building helpers"
mkdir -p $BIN $PLUGINS ${CONFIG:h} $PLIST:h
swiftc -O src/cachering.swift -o $BIN/cachering
swiftc -O src/cacheguide.swift -o $BIN/cacheguide
install -m 755 bin/cachewatch $BIN/cachewatch

print "→ Settings"
[[ -e $CONFIG ]] && print "  kept your existing $CONFIG" || cp config.example.zsh $CONFIG

print "→ Menu-bar plugin"
existing=($PLUGINS/cachewatch.*.sh(N))  # keep the refresh interval if you renamed it
plugin=${existing[1]:-$PLUGINS/cachewatch.6h.sh}
cat > $plugin <<EOF
#!/bin/zsh
# <xbar.title>cachewatch</xbar.title>
# <xbar.desc>Watches the hidden developer caches that quietly fill your Mac.</xbar.desc>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
exec $BIN/cachewatch --bar
EOF
chmod +x $plugin

print "→ Weekly check"
launchctl bootout gui/$UID/$LABEL 2>/dev/null || true
cat > $PLIST <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>$BIN/cachewatch</string><string>--notify</string></array>
  <!-- Sundays 10:00. If the Mac is asleep then, it runs once when it wakes. -->
  <key>StartCalendarInterval</key>
  <dict><key>Weekday</key><integer>0</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/cachewatch.err</string>
  <key>LowPriorityIO</key><true/>
  <key>Nice</key><integer>10</integer>
</dict>
</plist>
EOF
launchctl bootstrap gui/$UID $PLIST

if (( ! swiftbar )); then
  if (( brew )); then print "→ Installing SwiftBar"; brew install --cask swiftbar; swiftbar=1
  else print "\n! SwiftBar isn't installed. Get it free from https://swiftbar.app and the ring will appear."; fi
fi
if (( swiftbar )); then
  defaults read com.ameba.SwiftBar PluginDirectory >/dev/null 2>&1 || defaults write com.ameba.SwiftBar PluginDirectory $PLUGINS
  # A just-installed app isn't in macOS's app index yet, so fall back to its path.
  open -a SwiftBar 2>/dev/null || open /Applications/SwiftBar.app 2>/dev/null || open ~/Applications/SwiftBar.app 2>/dev/null ||
    print "\n! Couldn't start SwiftBar. Open it from Applications and the ring will appear."
  open -g "swiftbar://refreshplugin?name=cachewatch" 2>/dev/null || true  # a fresh launch loads plugins anyway
fi

print "
✓ Done. Look for the ring in your menu bar (it can take ~30 seconds the first time).
  Click it, then How to use, for a 2-minute tour.
  Allow notifications if macOS asks; that's how the weekly reminder reaches you.

  One click so the ring comes back after a restart:
  click the ring → SwiftBar → Preferences… → tick Launch at Login."
[[ :$PATH: == *:$BIN:* ]] || print "
  To use cachewatch in Terminal too, add ~/.local/bin to your PATH:
    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
