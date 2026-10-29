#!/bin/zsh
# Removes everything install.sh added. Your caches and SwiftBar itself are left alone.
cd ${0:A:h}

BIN=$HOME/.local/bin
LABEL=io.github.my-cmdhub.cachewatch
PLUGINS=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || print $HOME/.config/swiftbar)
PLUGINS=${PLUGINS/#\~/$HOME}

launchctl bootout gui/$UID/$LABEL 2>/dev/null
rm -f $HOME/Library/LaunchAgents/$LABEL.plist
rm -f $BIN/cachewatch $BIN/cachering $BIN/cacheguide $PLUGINS/cachewatch.*.sh(N)
open -g "swiftbar://refreshallplugins" 2>/dev/null
print "Removed the ring, the weekly check and the three helpers."

if read -q "?Also remove your settings and history? [y/N] "; then
  rm -rf $HOME/.config/cachewatch $HOME/Library/Logs/cachewatch.{log,baseline,err}(N)
  print "\nRemoved."
else
  print "\nKept ~/.config/cachewatch and ~/Library/Logs/cachewatch.*"
fi
print "SwiftBar is still installed in case other plugins use it. To remove it: brew uninstall --cask swiftbar"
