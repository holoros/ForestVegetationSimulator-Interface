#!/usr/bin/env python3
"""Offline tests for new_version.py against an in-memory model of the Zenodo deposit API.

Covers the two failure shapes seen on 25 September 2026 (an open draft with partial files, an open
draft with the complete file set, both making newversion answer 400) plus the clean path, the
read-back verification abort, --plan-only and --keep-inherited. No network.
"""
import hashlib, io, json, os, sys, tempfile, types, unittest
from pathlib import Path


class Resp:
    def __init__(self, status, body=None, text=None):
        self.status_code = status
        self._body = body
        self.text = text if text is not None else (json.dumps(body) if body is not None else "")
    @property
    def ok(self): return 200 <= self.status_code < 300
    def json(self): return self._body


class FakeZenodo:
    """Enough of the deposit API for new_version.py. Files carry md5 like the real thing."""
    API = "https://zenodo.org/api"

    def __init__(self, concept, latest_id, latest_version, draft=None, lose_after_upload=None):
        self.concept, self.latest_id, self.latest_version = concept, latest_id, latest_version
        self.draft = draft                        # dict or None
        self.next_id = 90001
        self.calls = []                           # (method, url)
        self.lose_after_upload = lose_after_upload
        self.published = False

    def _files_json(self):
        return [{"id": f["id"], "filename": n, "checksum": "md5:" + f["md5"], "filesize": f["size"]}
                for n, f in self.draft["files"].items()]

    def _draft_json(self):
        return {"id": self.draft["id"], "conceptrecid": self.concept, "submitted": False,
                "files": self._files_json(),
                "links": {"bucket": f"{self.API}/files/bucket-{self.draft['id']}",
                          "html": f"https://zenodo.org/deposit/{self.draft['id']}"}}

    # ---- requests surface
    def get(self, url, headers=None, params=None, timeout=None):
        self.calls.append(("GET", url))
        if url == f"{self.API}/records/{self.concept}/versions/latest":
            return Resp(200, {"id": self.latest_id, "metadata": {"version": self.latest_version}})
        if url == f"{self.API}/deposit/depositions/{self.latest_id}":
            links = {}
            if self.draft:
                links["latest_draft"] = f"{self.API}/deposit/depositions/{self.draft['id']}"
            return Resp(200, {"id": self.latest_id, "links": links})
        if self.draft and url == f"{self.API}/deposit/depositions/{self.draft['id']}":
            return Resp(200, self._draft_json())
        if url == f"{self.API}/deposit/depositions":
            return Resp(200, [self._draft_json()] if self.draft else [])
        return Resp(404, {"message": "not found"})

    def post(self, url, headers=None, json=None, timeout=None):
        self.calls.append(("POST", url))
        if url.endswith("/actions/newversion"):
            if self.draft and self.draft["files"]:
                return Resp(400, {"status": 400, "errors": [{"field": "files.enabled",
                            "messages": ["Please remove all files first."]}]},
                            text='{"errors":[{"field":"files.enabled","messages":["Please remove all files first."]}]}')
            if not self.draft:
                self.draft = {"id": self.next_id, "files": {}}
                self.next_id += 1
            return Resp(201, {"links": {"latest_draft": f"{self.API}/deposit/depositions/{self.draft['id']}"}})
        if url.endswith("/actions/publish"):
            self.published = True
            return Resp(202, {"doi": f"10.5281/zenodo.{self.draft['id']}",
                              "conceptdoi": f"10.5281/zenodo.{self.concept}",
                              "links": {"record_html": f"https://zenodo.org/records/{self.draft['id']}"}})
        return Resp(404, {})

    def put(self, url, headers=None, data=None, json=None, timeout=None):
        self.calls.append(("PUT", url))
        if "/files/bucket-" in url:
            name = url.rsplit("/", 1)[1]
            content = data.read()
            self.draft["files"][name] = {"id": f"fid-{name}", "md5": hashlib.md5(content).hexdigest(),
                                         "size": len(content)}
            if self.lose_after_upload == name:
                del self.draft["files"][name]       # simulate a file Zenodo silently dropped
            return Resp(201, {})
        if url == f"{self.API}/deposit/depositions/{self.draft['id']}":
            return Resp(200, {"metadata": {**json["metadata"], "prereserve_doi": {"doi": f"10.5281/zenodo.{self.draft['id']}"}}})
        return Resp(404, {})

    def delete(self, url, headers=None, timeout=None):
        self.calls.append(("DELETE", url))
        fid = url.rsplit("/", 1)[1]
        for n, f in list(self.draft["files"].items()):
            if f["id"] == fid:
                del self.draft["files"][n]
                return Resp(204, {})
        return Resp(404, {})


def make_stage(tmp, files):
    stage = Path(tmp) / "stage"; stage.mkdir()
    sums = []
    for name, content in files.items():
        p = stage / name; p.write_bytes(content)
        sums.append(f"{hashlib.sha256(content).hexdigest()}  {name}")
    (stage / "SHA256SUMS").write_text("\n".join(sums) + "\n")
    (stage / "files_to_upload.txt").write_text("\n".join(files) + "\n")
    (stage / "zenodo_metadata.json").write_text(json.dumps({"metadata": {"title": "t", "version": "1.9.2",
                                                             "upload_type": "dataset"}}))
    tok = Path(tmp) / "tok"; tok.write_text("not-a-real-token\n")
    return stage, tok


def run_nv(fake, stage, tok, extra=()):
    import importlib
    fake_requests = types.SimpleNamespace(get=fake.get, post=fake.post, put=fake.put, delete=fake.delete)
    sys.modules["requests"] = fake_requests
    sys.path.insert(0, str(Path(__file__).parent))
    if "new_version" in sys.modules:
        del sys.modules["new_version"]
    nv = importlib.import_module("new_version")
    argv = ["new_version.py", "--token-file", str(tok), "--parent-doi", f"10.5281/zenodo.{fake.concept}",
            "--expect-latest", str(fake.latest_id), "--metadata", str(stage / "zenodo_metadata.json"),
            "--files-list", str(stage / "files_to_upload.txt"), "--sha256sums", str(stage / "SHA256SUMS"),
            "--result", str(stage / "zenodo_dois.json")] + list(extra)
    old = sys.argv; sys.argv = argv
    out = io.StringIO(); old_out = sys.stdout; sys.stdout = out
    code = 0
    try:
        nv.main()
    except SystemExit as e:
        code = e.code if isinstance(e.code, int) else 1
    finally:
        sys.argv = old; sys.stdout = old_out
    return code, out.getvalue()


FILES = {"00_lead.png": b"PNG" * 50, "a.csv": b"a,b\n1,2\n", "b.csv": b"x\n" * 30, "SHA256SUMS": None}


class Tests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        files = {k: v for k, v in FILES.items() if v is not None}
        self.stage, self.tok = make_stage(self.tmp, files)
        # SHA256SUMS is itself in the manifest, as in the real deposit
        with open(self.stage / "files_to_upload.txt", "a") as fh: fh.write("SHA256SUMS\n")
        self.local = {p.name: hashlib.md5(p.read_bytes()).hexdigest()
                      for p in [self.stage / n for n in list(files) + ["SHA256SUMS"]]}

    def draft_with(self, names, wrong=(), extra=()):
        files = {}
        for n in names:
            m = self.local[n] if n not in wrong else "0" * 32
            files[n] = {"id": f"fid-{n}", "md5": m, "size": 1}
        for n in extra:
            files[n] = {"id": f"fid-{n}", "md5": "f" * 32, "size": 1}
        return {"id": 22959293, "files": files}

    def test_partial_draft_blocks_newversion_and_is_reused(self):
        """25 Sept run 2: a killed upload left 7 files; newversion answered 400."""
        fake = FakeZenodo("21081014", 22957726, "1.9.1", draft=self.draft_with(["00_lead.png", "a.csv"]))
        code, out = run_nv(fake, self.stage, self.tok, ["--publish"])
        self.assertEqual(code, 0, out)
        self.assertIn("Reusing it; newversion not called", out)
        self.assertIn("Sync plan: keep 2, delete 0, upload 2", out)
        self.assertIn("Verified: 4 files", out)
        self.assertTrue(fake.published)
        self.assertNotIn(("POST", f"{fake.API}/deposit/depositions/22957726/actions/newversion"), fake.calls)

    def test_complete_draft_reused_with_zero_uploads(self):
        """25 Sept run 3: the complete 75 file draft; newversion answered 400; should just publish."""
        fake = FakeZenodo("21081014", 22957726, "1.9.1",
                          draft=self.draft_with(["00_lead.png", "a.csv", "b.csv", "SHA256SUMS"]))
        code, out = run_nv(fake, self.stage, self.tok, ["--publish"])
        self.assertEqual(code, 0, out)
        self.assertIn("Sync plan: keep 4, delete 0, upload 0", out)
        self.assertEqual([c for c in fake.calls if c[0] == "PUT" and "bucket" in c[1]], [])
        self.assertTrue(fake.published)

    def test_changed_and_stale_files_are_replaced(self):
        fake = FakeZenodo("21081014", 22957726, "1.9.1",
                          draft=self.draft_with(["00_lead.png", "a.csv", "b.csv", "SHA256SUMS"],
                                                wrong=["b.csv"], extra=["retired.R"]))
        code, out = run_nv(fake, self.stage, self.tok)
        self.assertEqual(code, 0, out)
        self.assertIn("Sync plan: keep 3, delete 2, upload 1", out)
        self.assertIn("deleted retired.R", out)
        self.assertNotIn("retired.R", fake.draft["files"])
        self.assertEqual(fake.draft["files"]["b.csv"]["md5"], self.local["b.csv"])
        self.assertFalse(fake.published)      # no --publish
        self.assertIn("DRAFT only", out)

    def test_no_draft_creates_one(self):
        fake = FakeZenodo("21081014", 22957726, "1.9.1", draft=None)
        code, out = run_nv(fake, self.stage, self.tok)
        self.assertEqual(code, 0, out)
        self.assertIn("(created)", out)
        self.assertIn("Sync plan: keep 0, delete 0, upload 4", out)

    def test_readback_mismatch_aborts_before_publish(self):
        fake = FakeZenodo("21081014", 22957726, "1.9.1", draft=None, lose_after_upload="a.csv")
        code, out = run_nv(fake, self.stage, self.tok, ["--publish"])
        self.assertEqual(code, 4)
        self.assertFalse(fake.published)
        res = json.loads((self.stage / "zenodo_dois.json").read_text())
        self.assertIn("missing on Zenodo: a.csv", res["problems"])

    def test_plan_only_changes_nothing(self):
        fake = FakeZenodo("21081014", 22957726, "1.9.1",
                          draft=self.draft_with(["00_lead.png"], extra=["retired.R"]))
        code, out = run_nv(fake, self.stage, self.tok, ["--plan-only"])
        self.assertEqual(code, 0, out)
        self.assertIn("PLAN only. Nothing changed.", out)
        self.assertEqual([c for c in fake.calls if c[0] != "GET"], [])
        self.assertIn("retired.R", fake.draft["files"])

    def test_keep_inherited_skips_deletes(self):
        fake = FakeZenodo("21081014", 22957726, "1.9.1",
                          draft=self.draft_with(["00_lead.png", "a.csv", "b.csv", "SHA256SUMS"], extra=["retired.R"]))
        code, out = run_nv(fake, self.stage, self.tok, ["--keep-inherited"])
        # verification must then FAIL, because retired.R is still on the draft and not in the manifest
        self.assertEqual(code, 4, out)
        self.assertIn("not in manifest but on Zenodo: retired.R", out + json.dumps(json.loads((self.stage / "zenodo_dois.json").read_text())))

    def test_expect_latest_mismatch_refuses(self):
        fake = FakeZenodo("21081014", 22957726, "1.9.0", draft=None)
        code, out = run_nv(fake, self.stage, self.tok, ["--expect-latest", "22143872"])
        self.assertEqual(code, 3)
        self.assertEqual([c for c in fake.calls if c[0] != "GET"], [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
