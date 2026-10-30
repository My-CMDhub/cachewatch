# cachewatch settings. Changes show up on the next refresh.
# The installer copies this to ~/.config/cachewatch/config.zsh and never overwrites yours.

# Alert when your caches have grown this many GB since your last sweep.
GROW_GB=10

# Folders where your projects live. node_modules / .venv / .build inside them are
# listed in the menu so you can see them; cachewatch never deletes them.
PROJECTS=($HOME/Developer $HOME/Projects $HOME/code $HOME/src)

# Extra folders to watch, one per line: "Label|/full/path|clean command".
# Leave the command empty to make it look-only.
EXTRA_ITEMS=(
  # "Android SDK system images|$HOME/Library/Android/sdk/system-images|"
)

# How often the menu re-measures cache sizes (it reads every folder, ~30 s).
SIZES_EVERY_H=6

# Background check: tells you once when a developer tool is left running.
BG_CHECK=1          # 0 turns it off
CPU_HOG=50          # flag your own programs above this % CPU on two checks in a row
SIM_MIN=30          # flag a simulator or Docker Desktop left on longer than this (minutes)
BG_IGNORE=()        # names never to flag, e.g. (node "Google Chrome Helper")
