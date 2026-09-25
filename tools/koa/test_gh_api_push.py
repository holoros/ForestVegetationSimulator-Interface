#!/usr/bin/env python3
"""Offline tests for gh_api_push.py against an in-memory model of the GitHub Git Data API."""
import base64, hashlib, io, json, sys, tempfile, types, unittest
from pathlib import Path


class Resp:
    def __init__(self, status, body=None, content=None):
        self.status_code = status; self._body = body
        self.content = content if content is not None else (json.dumps(body).encode() if body is not None else b"")
        self.text = self.content.decode(errors="replace")
    def json(self): return self._body


class FakeGitHub:
    def __init__(self, repo, base, base_sha, base_file, existing_branches=()):
        self.repo, self.base, self.base_sha = repo, base, base_sha
        self.files = {base_sha: {"fvsOL/inst/extdata/HiGy.R": base_file}}
        self.refs = {base: base_sha}
        for b in existing_branches: self.refs[b] = "e" * 40
        self.blobs, self.trees, self.commits, self.prs, self.writes = {}, {}, {}, [], []

    def _p(self, url):
        return url.split(f"/repos/{self.repo}", 1)[1]

    def get(self, url, headers=None, timeout=None, params=None):
        p = self._p(url)
        if p.startswith("/git/ref/heads/"):
            b = p[len("/git/ref/heads/"):]
            return Resp(200, {"object": {"sha": self.refs[b]}}) if b in self.refs else Resp(404, {"message": "Not Found"})
        if p.startswith("/git/commits/"):
            sha = p.rsplit("/", 1)[1]
            return Resp(200, {"sha": sha, "tree": {"sha": "tree-" + sha[:6]}, "message": "HiGy.R 0.4.0: three stage mortality"})
        if p.startswith("/contents/"):
            path = p[len("/contents/"):]; ref = params["ref"]
            sha = self.refs.get(ref, ref)
            f = self.files.get(sha, {}).get(path)
            return Resp(200, content=f) if f is not None else Resp(404, {"message": "Not Found"})
        if p.startswith("/compare/"):
            a, b = p[len("/compare/"):].split("...")
            fa, fb = self.files[self.refs[a]], self.files[self.refs[b]]
            out = []
            for path in set(fa) | set(fb):
                if fa.get(path) != fb.get(path):
                    la, lb = fa.get(path, b"").splitlines(), fb.get(path, b"").splitlines()
                    out.append({"filename": path, "additions": max(len(lb) - len(la), 0) + 5, "deletions": 5})
            return Resp(200, {"files": out})
        return Resp(404, {})

    def post(self, url, headers=None, json=None, timeout=None):
        p = self._p(url); self.writes.append(p)
        if p == "/git/blobs":
            content = base64.b64decode(json["content"]); sha = hashlib.sha1(content).hexdigest()
            self.blobs[sha] = content; return Resp(201, {"sha": sha})
        if p == "/git/trees":
            sha = "tree-new"; self.trees[sha] = (json["base_tree"], json["tree"]); return Resp(201, {"sha": sha})
        if p == "/git/commits":
            sha = "c" * 40; parent = json["parents"][0]
            base_tree, entries = self.trees[json["tree"]]
            files = dict(self.files[parent]);
            for e in entries: files[e["path"]] = self.blobs[e["sha"]]
            self.files[sha] = files; self.commits[sha] = json; return Resp(201, {"sha": sha})
        if p == "/git/refs":
            b = json["ref"][len("refs/heads/"):]; self.refs[b] = json["sha"]; return Resp(201, {})
        if p == "/pulls":
            self.prs.append(json); return Resp(201, {"number": 7, "html_url": f"https://github.com/{self.repo}/pull/7"})
        return Resp(404, {})


BASE = b"VersionTag = \"HiGyV0.4.0\"\n" + b"x\n" * 20
NEW = b"VersionTag = \"HiGyV0.4.1\"\n" + b"y\n" * 25


def run(fake, extra=(), new=NEW, expect_base=None, expect_new=None, single=True):
    tmp = Path(tempfile.mkdtemp())
    (tmp / "HiGy_041.R").write_bytes(new); (tmp / "msg.txt").write_text("HiGy 0.4.1\n\nbody\n"); (tmp / "tok").write_text("tok-not-real\n")
    sys.modules["requests"] = types.SimpleNamespace(get=fake.get, post=fake.post)
    sys.path.insert(0, str(Path(__file__).parent))
    sys.modules.pop("gh_api_push", None)
    import gh_api_push as g
    argv = ["gh_api_push.py", "--repo", fake.repo, "--base", fake.base, "--branch", "koa/higy-0.4.1",
            "--message-file", str(tmp / "msg.txt"), "--token-file", str(tmp / "tok"),
            "--result", str(tmp / "out.json")]
    if single:
        argv += ["--path", "fvsOL/inst/extdata/HiGy.R", "--file", str(tmp / "HiGy_041.R"),
                 "--expect-base-md5", expect_base or hashlib.md5(BASE).hexdigest(),
                 "--expect-new-md5", expect_new or hashlib.md5(new).hexdigest()]
    else:
        (tmp / "a.py").write_bytes(b"#!/usr/bin/env python3\nprint(1)\n"); (tmp / "b.sh").write_bytes(b"echo hi\n")
        argv += ["--add", f"tools/koa/a.py={tmp / 'a.py'}", "--add", f"tools/koa/b.sh={tmp / 'b.sh'}"]
    argv += list(extra)
    old = sys.argv; sys.argv = argv; out = io.StringIO(); so, se = sys.stdout, sys.stderr; sys.stdout = out; sys.stderr = out
    code = 0
    try: g.main()
    except SystemExit as e: code = e.code if isinstance(e.code, int) else 1
    finally: sys.argv = old; sys.stdout, sys.stderr = so, se
    res = json.loads((tmp / "out.json").read_text()) if (tmp / "out.json").exists() else None
    return code, out.getvalue(), res


class Tests(unittest.TestCase):
    def fresh(self, **kw):
        return FakeGitHub("holoros/ForestVegetationSimulator-Interface", "ClaudeDevelopment", "8" * 40, BASE, **kw)

    def test_happy_path_with_pr(self):
        fake = self.fresh()
        code, out, res = run(fake, ["--expect-numstat", "10", "5", "--pr-title", "HiGy 0.4.1"])
        self.assertEqual(code, 0, out)
        self.assertEqual(fake.refs["koa/higy-0.4.1"], "c" * 40)
        self.assertEqual(fake.files["c" * 40]["fvsOL/inst/extdata/HiGy.R"], NEW)
        self.assertEqual(res["pr_number"], 7); self.assertIn("gate E ok", out)
        self.assertNotIn("tok-not-real", out)

    def test_dry_run_writes_nothing(self):
        fake = self.fresh()
        code, out, res = run(fake, ["--dry-run"])
        self.assertEqual(code, 0, out); self.assertEqual(fake.writes, []); self.assertTrue(res["dry_run"])

    def test_base_moved_is_refused(self):
        fake = self.fresh()
        code, out, res = run(fake, expect_base="0" * 32)
        self.assertEqual(code, 1); self.assertIn("gate C", out); self.assertEqual(fake.writes, [])

    def test_existing_branch_is_refused(self):
        fake = self.fresh(existing_branches=["koa/higy-0.4.1"])
        code, out, res = run(fake)
        self.assertEqual(code, 1); self.assertIn("already exists", out); self.assertEqual(fake.writes, [])

    def test_wrong_artifact_is_refused(self):
        fake = self.fresh()
        code, out, res = run(fake, expect_new="1" * 32)
        self.assertEqual(code, 1); self.assertIn("gate A", out); self.assertEqual(fake.writes, [])

    def test_numstat_mismatch_is_reported_after_write(self):
        fake = self.fresh()
        code, out, res = run(fake, ["--expect-numstat", "99", "1"])
        self.assertEqual(code, 1); self.assertIn("gate E4", out)

    def test_token_masked_in_errors(self):
        fake = self.fresh()
        def bad_post(url, headers=None, json=None, timeout=None):
            return Resp(422, content=b'{"message":"bad tok-not-real here"}')
        fake.post = bad_post
        code, out, res = run(fake)
        self.assertEqual(code, 1); self.assertIn("***", out); self.assertNotIn("tok-not-real", out)


class MultiFile(unittest.TestCase):
    def fresh(self):
        return FakeGitHub("holoros/ForestVegetationSimulator-Interface", "ClaudeDevelopment", "8" * 40, BASE)

    def test_two_new_files_land_and_verify(self):
        fake = self.fresh()
        code, out, res = run(fake, ["--pr-title", "tools"], single=False)
        self.assertEqual(code, 0, out)
        files = fake.files["c" * 40]
        self.assertIn("tools/koa/a.py", files); self.assertIn("tools/koa/b.sh", files)
        self.assertIn("fvsOL/inst/extdata/HiGy.R", files)          # base tree carried over
        self.assertEqual(res["files"], ["tools/koa/a.py", "tools/koa/b.sh"])
        self.assertIn("2 file(s) verified", out)
        # executable bit only for a shebang script
        entries = {e["path"]: e["mode"] for e in fake.trees["tree-new"][1]}
        self.assertEqual(entries["tools/koa/a.py"], "100755"); self.assertEqual(entries["tools/koa/b.sh"], "100644")

    def test_existing_path_refused_without_allow_overwrite(self):
        fake = self.fresh()
        fake.files[fake.base_sha]["tools/koa/a.py"] = b"old\n"
        code, out, res = run(fake, single=False)
        self.assertEqual(code, 1); self.assertIn("already exists", out); self.assertEqual(fake.writes, [])
        code, out, res = run(fake, ["--allow-overwrite"], single=False)
        self.assertEqual(code, 0, out)

    def test_mixed_single_and_add(self):
        fake = self.fresh()
        tmp = Path(tempfile.mkdtemp()); (tmp / "x.txt").write_bytes(b"x\n")
        code, out, res = run(fake, ["--add", f"tools/koa/x.txt={tmp / 'x.txt'}"])
        self.assertEqual(code, 0, out)
        self.assertEqual(sorted(res["files"]), ["fvsOL/inst/extdata/HiGy.R", "tools/koa/x.txt"])

    def test_duplicate_paths_refused(self):
        fake = self.fresh()
        tmp = Path(tempfile.mkdtemp()); (tmp / "x.txt").write_bytes(b"x\n")
        code, out, res = run(fake, ["--add", f"fvsOL/inst/extdata/HiGy.R={tmp / 'x.txt'}"])
        self.assertEqual(code, 1); self.assertIn("duplicate repository paths", out)


if __name__ == "__main__":
    unittest.main(verbosity=1)
