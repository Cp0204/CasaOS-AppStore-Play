#!/usr/bin/env bash
# Build the CasaOS v1 (zip) app store packages, one per architecture.
#
# This is the v1 store only: four zips plus the root json manifests that older
# CasaOS clients pull from
#   https://play.cuse.eu.org/Cp0204-AppStore-Play[-<arch>].zip
# The v2 store (index.json / dist) is built by .github/workflows/release-v2.yml.
#
# The previous implementation filtered apps with
#     grep -rlPz 'x-casaos:\s*\n\s*architectures:[\n\s\w-#]*- arm\s*\n'
# which requires `architectures:` to be the *first* key under `x-casaos:`.
# After the v2 refactor every app has `id:` in front, so nothing matched and
# AppStore_amd64.zip ended up with zero apps.
#
# Here one awk pass reads every compose file and extracts the architecture list
# (block style `- arm`, flow style `[amd64, arm64]`, inline comments, quotes,
# CRLF; key order irrelevant). Everything else is table lookups, so the whole
# build costs a handful of forks instead of one subprocess per app.
set -euo pipefail

ARCHITECTURES=(amd64 arm arm64)
ROOT_MANIFESTS=(recommend-list.json supported-languages.json category-list.json store-config.json)

# "arch|App" -> 1
declare -A ARCH_MAP=()

load_arch_map() {
  local file arch app rest
  while IFS=$'\t' read -r file arch; do
    [ -n "$file" ] || continue
    rest=${file#Apps/}
    app=${rest%%/*}
    ARCH_MAP["$arch|$app"]=1
  done < <(
    awk '
      { sub(/\r$/, "") }   # tolerate CRLF compose files
      FNR == 1 { casa = 0; arch = 0 }
      /^x-casaos:[[:space:]]*(#.*)?$/ { casa = 1; arch = 0; next }
      casa && /^[^[:space:]#]/ { casa = 0; arch = 0 }
      casa && /^[[:space:]]+architectures:[[:space:]]*$/ { arch = 1; next }
      casa && /^[[:space:]]+architectures:[[:space:]]*\[/ {
        line = $0
        sub(/^[^[]*\[/, "", line); sub(/\].*$/, "", line)
        n = split(line, parts, ",")
        for (i = 1; i <= n; i++) {
          v = parts[i]; gsub(/^[[:space:]"\047]+|[[:space:]"\047]+$/, "", v)
          if (v != "") print FILENAME "\t" tolower(v)
        }
        arch = 0; next
      }
      arch && /^[[:space:]]*-[[:space:]]*/ {
        v = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", v); sub(/[[:space:]]*#.*$/, "", v)
        gsub(/^[\047"]|[\047"]$/, "", v)
        if (v != "") print FILENAME "\t" tolower(v)
        next
      }
      arch && /^[[:space:]]*(#.*)?$/ { next }
      arch { arch = 0 }
    ' Apps/*/docker-compose.yml
  )
}

write_package() {
  local out=$1 arch=${2:-} stage rest app y key
  local files=()

  for y in Apps/*/docker-compose.yml; do
    rest=${y#Apps/}
    app=${rest%%/*}
    if [ -z "$arch" ]; then
      files+=("$y")
      continue
    fi
    key="$arch|$app"
    if [ -n "${ARCH_MAP[$key]+set}" ]; then
      files+=("$y")
    fi
  done

  stage=$(mktemp -d)
  if [ ${#files[@]} -gt 0 ]; then
    cp --parents "${files[@]}" "$stage/"
  fi

  # Per-architecture overlay: adds apps and overrides the generic entry.
  if [ -n "$arch" ] && [ -d "Apps_$arch" ]; then
    for y in "Apps_$arch"/*/docker-compose.yml; do
      [ -e "$y" ] || continue
      rest=${y#Apps_$arch/}
      app=${rest%%/*}
      mkdir -p "$stage/Apps/$app"
      cp "$y" "$stage/Apps/$app/docker-compose.yml"
    done
  fi

  for y in "${ROOT_MANIFESTS[@]}"; do
    [ -e "$y" ] && cp "$y" "$stage/"
  done

  rm -f "$out"
  ( cd "$stage" && zip -qrD "$OLDPWD/$out" . )
  rm -rf "$stage"

  printf '%s: %s apps\n' "$out" "$(unzip -l "$out" | grep -c 'Apps/.*/docker-compose.yml')"
}

main() {
  local counts arch n

  load_arch_map
  counts="universal($(ls -d Apps/*/ | wc -l))"

  write_package "AppStore.zip" ""

  for arch in "${ARCHITECTURES[@]}"; do
    write_package "AppStore_$arch.zip" "$arch"
    n=$(unzip -l "AppStore_$arch.zip" | grep -c 'Apps/.*/docker-compose.yml')
    counts="$counts, $arch($n)"
  done

  echo "app_counts=$counts"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf 'app_counts=%s\n' "$counts" >> "$GITHUB_OUTPUT"
  fi
}

main "$@"
