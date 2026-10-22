# Shoalcheck krew index

A custom [krew](https://krew.sigs.k8s.io) index for [Shoalcheck](https://shoalcheck.com), a read-only Kubernetes preflight and audit CLI. The official krew-index requires an open-source plugin, so Shoalcheck is distributed from its own index.

```sh
kubectl krew index add shoalcheck https://github.com/Shoalcheck/krew-index
kubectl krew install shoalcheck/shoalcheck
kubectl shoalcheck --version
```

Shoalcheck is read-only: it uses `get` and `list` only. `kubectl shoalcheck audit --show-permissions` prints the RBAC it needs.

## Maintaining

`scripts/update.sh <version>` downloads that release's `checksums.txt` and cosign bundle, verifies the signature with `scripts/cosign.pub` (needs `cosign`), and regenerates `plugins/shoalcheck.yaml` with the checksum of every archive. Commit the result after each release.

Test locally: `kubectl krew install --manifest=plugins/shoalcheck.yaml`.
