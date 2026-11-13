#!/usr/bin/env bash
# Install the agentic-delivery team (agents, skills, commands) globally for
# OpenCode by symlinking .opencode/{agents,skills,commands} into
# ~/.config/opencode/.
#
# Because everything is symlinked, `git pull` in this repo updates the
# global install instantly — no need to re-run this script after pulls.
# OpenCode watches these files and hot-reloads; use /reload to force it.
#
# Safe to re-run: existing symlinks are refreshed. Real files/directories
# with the same name are never touched — they are reported and skipped.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    echo "SKIP: $dst exists and is not a symlink (remove it first if you want it replaced)" >&2
    return 0
  fi
  ln -s "$src" "$dst"
  echo "linked  $dst -> $src"
}

for agent in "$REPO_ROOT"/.opencode/agents/*.md; do
  link "$agent" "$DEST_ROOT/agents/$(basename "$agent")"
done

for skill_dir in "$REPO_ROOT"/.opencode/skills/*/; do
  link "${skill_dir%/}" "$DEST_ROOT/skills/$(basename "$skill_dir")"
done

for command in "$REPO_ROOT"/.opencode/commands/*.md; do
  link "$command" "$DEST_ROOT/commands/$(basename "$command")"
done

echo
echo "Done. /rfe, /cve, /grade and the delivery team are now available in"
echo "every project. Uninstall by deleting the symlinks under $DEST_ROOT."
