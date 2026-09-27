# Koa tooling (holoros, 25 September 2026)

Launchers and their offline tests for the koa growth and yield release chain. Nothing here is part of
the R package; this directory sits outside `fvsOL/` on purpose so it never ships in a build.

`gh_api_push.py` commits one or several files to a new branch on a GitHub repository through the Git
Data API, with gates on the local artifact md5, the remote baseline md5 (or the path being free),
the branch being free, the changed file set and numstat, and a read back of the ref and every blob
off the server before it reports success. It opens the pull request when asked. It needs only
`python3` and `requests`, no `git`, no `gh`, no credential in any URL. Written after the git based
launcher failed on a host with no git and behind a proxy that refused the push.

`PUSH_fvshi_api.sh` wraps it for a HiGy.R release on `ClaudeDevelopment`: artifact md5, Rscript parity
against the deposit carrier, then a dry run that exercises every remote read, then `PUSH=1` to land.

`zenodo/new_version.py` cuts a new version of a Zenodo concept record. It finds an open draft before
calling `newversion` (which answers HTTP 400 once a draft holds files), syncs the draft to the manifest
by md5 rather than emptying it, reads the draft back and refuses to publish unless every file matches,
and has `--plan-only`.

Tests: `python3 test_gh_api_push.py` and `python3 zenodo/test_new_version.py` run against in memory
models of the two APIs in under a second and need no token.
