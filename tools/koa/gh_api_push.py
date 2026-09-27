#!/usr/bin/env python3
"""
gh_api_push.py -- commit one file to a new branch on GitHub through the Git Data API, gated, and
verify it off the server. No git binary, no clone, no credential in any URL or config file.

Why this exists (25 September 2026). The FVS-HI 0.4.1 launcher cloned with git and pushed with the
token in the remote URL. It failed three ways on the day it was needed: firebreather has no git, the
cloud container's git proxy refuses pushes to repositories outside its session allow-list, and the
launcher named the repository wrongly ("holoros/ClaudeDevelopment", which is a branch name) because
its dry run stopped before the clone and never exercised the name. The push that worked went through
the REST Git Data API with `requests`, which every machine here has. This is that path, generalized.

Flow: read base ref -> read base commit tree -> GET the target blob raw and gate its md5 -> POST blob
-> POST tree (base_tree + one path) -> POST commit (parents=[base]) -> POST ref -> GET ref back and
GET the blob raw at the new ref and gate both -> compare base...branch and require exactly one file
with the expected numstat -> optionally POST a pull request. Every gate names the value it saw.

    python3 gh_api_push.py --repo holoros/ForestVegetationSimulator-Interface \
        --base ClaudeDevelopment --branch koa/higy-0.4.1-bal-of-record \
        --path fvsOL/inst/extdata/HiGy.R --file HiGy_041.R \
        --expect-base-md5 cde569e90c359df39a498cb01941d58b \
        --expect-new-md5 d0780204943c6c494f93e16a9459aebd \
        --expect-numstat 44 12 --message-file commit_msg.txt --token-file token \
        [--pr-title "..."] [--pr-body-file body.md] [--dry-run]

Several files: repeat --add REPO_PATH=LOCAL_FILE. A path that already exists at --base is refused
unless --allow-overwrite is given, so a tooling drop cannot silently clobber a file; --path/--file
remains the single-file form with its md5 gates.

--dry-run performs every GET and every gate that can be checked before writing (base ref, base blob
md5, branch absence, artifact md5) and stops. The token is read from --token-file, sent only as a
Bearer header, and never printed; a failing response body is printed only after the token string is
masked out of it.
"""
import argparse, base64, hashlib, json, sys, time
from pathlib import Path
import requests

API = "https://api.github.com"


class Gate(Exception):
    pass


def md5b(b):
    return hashlib.md5(b).hexdigest()


class GH:
    def __init__(self, repo, token, log):
        self.repo, self.token, self.log = repo, token, log
        self.h = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json",
                  "X-GitHub-Api-Version": "2022-11-28"}

    def _chk(self, r, what, ok=(200, 201)):
        if r.status_code not in ok:
            body = r.text.replace(self.token, "***")[:400]
            raise Gate(f"{what}: HTTP {r.status_code} {body}")
        return r

    def get(self, path, raw=False, **kw):
        h = dict(self.h)
        if raw:
            h["Accept"] = "application/vnd.github.raw"
        r = requests.get(f"{API}/repos/{self.repo}{path}", headers=h, timeout=60, **kw)
        return r

    def post(self, path, body, what):
        r = requests.post(f"{API}/repos/{self.repo}{path}", headers=self.h, json=body, timeout=120)
        return self._chk(r, what).json()

    def ref(self, branch):
        return self.get(f"/git/ref/heads/{branch}")

    def raw(self, path, ref):
        r = self.get(f"/contents/{path}", raw=True, params={"ref": ref})
        self._chk(r, f"raw {path}@{ref[:12]}")
        return r.content


def run(a):
    log = open(a.log, "a") if a.log else None

    def say(s):
        print(s, flush=True)
        if log:
            log.write(s + "\n"); log.flush()

    token = Path(a.token_file).expanduser().read_text().strip()
    if not token:
        raise Gate(f"token file {a.token_file} is empty")
    gh = GH(a.repo, token, log)
    say(f"== gh_api_push {time.strftime('%Y-%m-%dT%H:%M:%S%z')} repo {a.repo} base {a.base} -> {a.branch}"
        f"  mode {'DRY RUN' if a.dry_run else 'WRITE'}")

    # the set of files to commit: (repo_path, local_path, bytes, md5, expected_base_md5 or None)
    entries = []
    if a.path or a.file:
        if not (a.path and a.file):
            raise Gate("--path and --file go together")
        entries.append((a.path, Path(a.file), a.expect_base_md5))
    for spec in a.add:
        if "=" not in spec:
            raise Gate(f"--add wants REPO_PATH=LOCAL_FILE, got {spec!r}")
        rp, lf = spec.split("=", 1)
        entries.append((rp.strip(), Path(lf), None))
    if not entries:
        raise Gate("nothing to commit: give --path/--file or at least one --add")
    seen = [e[0] for e in entries]
    if len(set(seen)) != len(seen):
        raise Gate(f"duplicate repository paths: {sorted({p for p in seen if seen.count(p) > 1})}")

    # gate A: the local artifact is the one that was tested (md5 gate applies to the single-file form)
    files = []
    for rp, lf, exp_base in entries:
        b = lf.read_bytes()
        m = md5b(b)
        if a.expect_new_md5 and rp == a.path and m != a.expect_new_md5:
            raise Gate(f"gate A: {lf} md5 {m} is not the expected {a.expect_new_md5}")
        files.append({"path": rp, "local": lf, "bytes": b, "md5": m, "expect_base": exp_base})
        nl = b.count(b"\n")
        say(f"gate A ok: {lf.name} -> {rp}  md5 {m}, {nl} lines")

    # base ref and commit
    r = gh._chk(gh.ref(a.base), f"base ref {a.base}")
    base_sha = r.json()["object"]["sha"]
    commit = gh._chk(gh.get(f"/git/commits/{base_sha}"), "base commit").json()
    tree_sha = commit["tree"]["sha"]
    say(f"base {a.base} @ {base_sha[:12]}  ({commit['message'].splitlines()[0][:70]})")

    # gate C: for a replaced file, the remote is the baseline the change was measured against;
    # for an added file, the path must be free unless --allow-overwrite
    for f in files:
        rr = gh.get(f"/contents/{f['path']}", raw=True, params={"ref": base_sha})
        if rr.status_code == 404:
            if f["expect_base"]:
                raise Gate(f"gate C: {f['path']} does not exist at {a.base}, but --expect-base-md5 was given")
            f["exists"] = False
            say(f"gate C ok: {f['path']} is new at {a.base}")
            continue
        gh._chk(rr, f"raw {f['path']}@{a.base}")
        bm = md5b(rr.content)
        f["exists"] = True
        if f["expect_base"] and bm != f["expect_base"]:
            raise Gate(f"gate C: {f['path']} at {a.base} has md5 {bm}, expected {f['expect_base']}; "
                       "the remote moved since the change was measured")
        if not f["expect_base"] and not a.allow_overwrite:
            raise Gate(f"gate C: {f['path']} already exists at {a.base} (md5 {bm}); pass --allow-overwrite "
                       "or --expect-base-md5 to replace it deliberately")
        if bm == f["md5"]:
            raise Gate(f"nothing to do for {f['path']}: remote already equals the local file")
        say(f"gate C ok: remote {f['path']} md5 {bm} will be replaced")

    # gate: the target branch must not exist
    rb = gh.ref(a.branch)
    if rb.status_code != 404:
        raise Gate(f"branch {a.branch} already exists on the remote (HTTP {rb.status_code}); refusing")
    say(f"gate ok: branch {a.branch} is free")

    if a.dry_run:
        say(f"DRY RUN complete. {len(files)} file(s) would be committed. Nothing written.")
        return {"dry_run": True, "base_sha": base_sha, "files": [f["path"] for f in files]}

    # write
    tree_entries = []
    for f in files:
        blob = gh.post("/git/blobs", {"content": base64.b64encode(f["bytes"]).decode(), "encoding": "base64"},
                       f"create blob {f['path']}")["sha"]
        mode = "100755" if f["local"].suffix in (".sh", ".py") and f["bytes"].startswith(b"#!") else "100644"
        tree_entries.append({"path": f["path"], "mode": mode, "type": "blob", "sha": blob})
    tree = gh.post("/git/trees", {"base_tree": tree_sha, "tree": tree_entries}, "create tree")["sha"]
    msg = Path(a.message_file).read_text()
    body = {"message": msg, "tree": tree, "parents": [base_sha]}
    if a.author_name and a.author_email:
        body["author"] = {"name": a.author_name, "email": a.author_email}
    c = gh.post("/git/commits", body, "create commit")["sha"]
    gh.post("/git/refs", {"ref": f"refs/heads/{a.branch}", "sha": c}, "create ref")
    say(f"commit {c}")

    # gate E: verify off the server, never off the response of the write
    got = gh._chk(gh.ref(a.branch), "verify ref").json()["object"]["sha"]
    if got != c:
        raise Gate(f"gate E1: ref {a.branch} is {got}, commit written was {c}")
    for f in files:
        sm = md5b(gh.raw(f["path"], a.branch))
        if sm != f["md5"]:
            raise Gate(f"gate E2: server blob md5 {sm} for {f['path']} differs from local {f['md5']}")
    cmp = gh._chk(gh.get(f"/compare/{a.base}...{a.branch}"), "compare").json()
    cfiles = cmp.get("files", [])
    want = sorted(f["path"] for f in files)
    if sorted(x["filename"] for x in cfiles) != want:
        raise Gate(f"gate E3: compare shows {sorted(x['filename'] for x in cfiles)}, expected {want}")
    add = sum(x["additions"] for x in cfiles); dele = sum(x["deletions"] for x in cfiles)
    if a.expect_numstat and (add, dele) != tuple(a.expect_numstat):
        raise Gate(f"gate E4: numstat {add}/{dele} differs from expected {a.expect_numstat[0]}/{a.expect_numstat[1]}")
    say(f"gate E ok: ref {got[:12]} == commit, {len(files)} file(s) verified by md5 off the server, +{add} -{dele}")
    sm = ",".join(f["md5"][:8] for f in files)

    out = {"commit": c, "branch": a.branch, "base_sha": base_sha, "files": [f["path"] for f in files],
           "blob_md5": sm, "additions": add, "deletions": dele,
           "compare_url": f"https://github.com/{a.repo}/compare/{a.base}...{a.branch}?expand=1"}
    if a.pr_title:
        prb = Path(a.pr_body_file).read_text() if a.pr_body_file else msg
        pr = gh.post("/pulls", {"title": a.pr_title, "head": a.branch, "base": a.base, "body": prb, "draft": False}, "create pull request")
        out.update(pr_number=pr["number"], pr_url=pr["html_url"])
        say(f"PR {pr['number']} {pr['html_url']}")
    else:
        say(f"open the PR at {out['compare_url']}")
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--repo", required=True, help="owner/name")
    ap.add_argument("--base", required=True, help="branch to commit on top of")
    ap.add_argument("--branch", required=True, help="new branch to create; must not exist")
    ap.add_argument("--path", help="path of the file inside the repository (single-file form)")
    ap.add_argument("--file", help="local file whose bytes become that path (single-file form)")
    ap.add_argument("--add", action="append", default=[], metavar="REPO_PATH=LOCAL_FILE",
                    help="additional or sole files to commit; repeatable")
    ap.add_argument("--allow-overwrite", action="store_true",
                    help="let an --add path replace a file that already exists at --base")
    ap.add_argument("--expect-base-md5", help="md5 the remote file must have at --base")
    ap.add_argument("--expect-new-md5", help="md5 --file must have")
    ap.add_argument("--expect-numstat", nargs=2, type=int, metavar=("ADD", "DEL"))
    ap.add_argument("--message-file", required=True)
    ap.add_argument("--token-file", required=True)
    ap.add_argument("--author-name", default="Aaron Weiskittel")
    ap.add_argument("--author-email", default="aaron.weiskittel@maine.edu")
    ap.add_argument("--pr-title")
    ap.add_argument("--pr-body-file")
    ap.add_argument("--result", help="write the outcome as JSON here")
    ap.add_argument("--log")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    try:
        out = run(a)
    except Gate as g:
        print(f"STOP: {g}", file=sys.stderr)
        sys.exit(1)
    if a.result:
        Path(a.result).write_text(json.dumps(out, indent=2) + "\n")


if __name__ == "__main__":
    main()
