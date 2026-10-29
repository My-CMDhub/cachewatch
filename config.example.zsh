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
