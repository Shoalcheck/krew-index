#!/usr/bin/env bash
# Regenerate plugins/shoalcheck.yaml from a published Shoalcheck release.
# Usage: scripts/update.sh <version>   e.g. scripts/update.sh 0.1.0-rc.12   (leading v accepted)
# Verifies checksums.txt against its cosign bundle with scripts/cosign.pub BEFORE trusting any hash in it.
set -euo pipefail
ver="${1:?usage: $0 <version>}"; ver="${ver#v}"
repo="${SHOALCHECK_REPO:-Shoalcheck/shoalcheck}"
here="$(cd "$(dirname "$0")" && pwd)"
out="$here/../plugins/shoalcheck.yaml"
base="https://github.com/$repo/releases/download/v$ver"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
command -v cosign >/dev/null || { echo "cosign is required" >&2; exit 1; }
for f in checksums.txt checksums.txt.sigstore.json; do curl -fsSL -o "$tmp/$f" "$base/$f"; done
cosign verify-blob --key "$here/cosign.pub" --bundle "$tmp/checksums.txt.sigstore.json" "$tmp/checksums.txt"

sum() { # archive name -> sha256, fail if absent
  local s; s="$(awk -v f="$1" '$2==f {print $1}' "$tmp/checksums.txt")"
  [ -n "$s" ] || { echo "no checksum for $1" >&2; exit 1; }; echo "$s"
}
platform() { # os arch ext binary
  local a="kubectl-shoalcheck_${ver}_$1_$2.$3"
  cat <<P
  - selector:
      matchLabels:
        os: $1
        arch: $2
    uri: $base/$a
    sha256: $(sum "$a")
    files:
    - from: $4
      to: .
    - from: LICENSE
      to: .
    bin: $4
P
}
{
cat <<'H'
apiVersion: krew.googlecontainertools.github.com/v1alpha2
kind: Plugin
metadata:
  name: shoalcheck
spec:
  version: VERSION_PLACEHOLDER
  homepage: https://shoalcheck.com
  shortDescription: Read-only preflight and audit of a Kubernetes cluster
  description: |
    Shoalcheck reads a cluster and reports what is wrong, what a change would
    break, and what it costs: audit, upgrade and drain preflight, and a CI gate
    that fails a pipeline on what changed. Findings carry their evidence and
    say what could not be read instead of passing it.
  caveats: |
    Shoalcheck is read-only: it uses get and list only and never writes to the
    cluster. Run `kubectl shoalcheck audit --show-permissions` to see the exact
    RBAC it needs. Some commands (such as gate) need a Team licence key; see
    https://shoalcheck.com.
  platforms:
H
platform darwin amd64 tar.gz kubectl-shoalcheck
platform darwin arm64 tar.gz kubectl-shoalcheck
platform linux amd64 tar.gz kubectl-shoalcheck
platform linux arm64 tar.gz kubectl-shoalcheck
platform windows amd64 zip kubectl-shoalcheck.exe
platform windows arm64 zip kubectl-shoalcheck.exe
} | sed "s/VERSION_PLACEHOLDER/v$ver/" > "$out"
echo "wrote $out for v$ver"
