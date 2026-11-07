#!/usr/bin/env bash
# Protect the koa scripts that the Zenodo record links by commit (they are on no branch since ClaudeDevelopment was rebuilt).
# Run from any machine with push access to holoros/ForestVegetationSimulator-Interface (gh authenticated as holoros).
set -euo pipefail
R=holoros/ForestVegetationSimulator-Interface
for pair in koa-v105final:ecdb5a01e12f2f7e867e8fad9a3c893f63fdb282 koa-a5:ac9ee9b4168b3ae1fd6ccb4724f09cab36b99dac koa-v104:977c9591008bf639ade52e4b61fb3486069890fa koa-v103:2adddc73f10120e6c0c95a8fb9227000ce73b73d; do
  tag=${pair%%:*}; sha=${pair##*:}
  gh api repos/$R/git/refs -f ref=refs/tags/$tag -f sha=$sha >/dev/null && echo "tagged $tag -> ${sha:0:7}" || echo "skip $tag (exists or no access)"
done
