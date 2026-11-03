#!/usr/bin/env bash
# Re-clone upstream docker_open5gs at the pinned commit and overlay local changes.
# Usage: ./setup.sh [target_dir]   (default: ./docker_open5gs, git-ignored)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HERE/docker_open5gs}"
# shellcheck disable=SC1091
source <(grep -E '^(url|commit)=' "$HERE/UPSTREAM")

if [ ! -d "$TARGET/.git" ]; then
  git clone "$url" "$TARGET"
fi
git -C "$TARGET" fetch --quiet origin
git -C "$TARGET" checkout --quiet "$commit"
echo "Upstream $url @ $commit -> $TARGET"

# Keep upstream's .env to fill in values marked CHANGE_ME (e.g. test SIM K/OP)
cp "$TARGET/.env" "$TARGET/.env.upstream"

# Overlay every file in overrides/ (env.example becomes .env)
cd "$HERE/overrides"
find . -type f | while read -r f; do
  rel="${f#./}"
  dest="$rel"; [ "$rel" = "env.example" ] && dest=".env"
  mkdir -p "$TARGET/$(dirname "$dest")"
  cp "$rel" "$TARGET/$dest"
  echo "  overlay: $dest"
done

# Fill CHANGE_ME values from upstream defaults (edit .env to use your own SIM)
while IFS='=' read -r key _; do
  val="$(grep -E "^${key}=" "$TARGET/.env.upstream" | head -1 | cut -d= -f2-)"
  if [ -n "$val" ]; then
    sed -i "s|^${key}=CHANGE_ME$|${key}=${val}|" "$TARGET/.env"
    echo "  .env: $key taken from upstream default"
  else
    echo "  WARNING: $key is CHANGE_ME, set it in $TARGET/.env"
  fi
done < <(grep -E '^[A-Za-z0-9_]+=CHANGE_ME$' "$TARGET/.env")
rm -f "$TARGET/.env.upstream"

echo "Done. Next: cd $TARGET && see ../README.md (RAN quick start)."
