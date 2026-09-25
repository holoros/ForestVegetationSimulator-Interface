#!/usr/bin/env python3
"""
new_version.py -- cut a new version of an existing Zenodo concept record (legacy deposit API).

Based on the zenodo_v62 uploader (2026-07-30) with these changes for Koa 1.8.0 (2026-09-17):
  * --parent-doi 10.5281/zenodo.NNN (concept DOI) is accepted; --concept-record-id still works.
  * --expect-latest RECID refuses to proceed unless the latest PUBLISHED version is that record.
  * Every manifest file is checked before any network call: present, unique basename (Zenodo lists
    files flat) and, with --sha256sums, matching the checksum written by check_deposit.py.
  * --result writes zenodo_dois.json (draft id, reserved version DOI, edit URL, publish state).

Revision of 2026-09-25, after the 1.9.1 publish failed twice at the newversion action:
  * Zenodo's newversion action does NOT return an open draft once that draft holds files. It answers
    HTTP 400 "files.enabled: Please remove all files first". Two runs on 25 September 2026 died there,
    one after a killed upload had left a 7 file draft, one with the complete 75 file draft the previous
    run had built. The script now LOOKS FOR an open draft on the concept first (the latest published
    deposition's links.latest_draft, then the account's draft list by conceptrecid) and calls
    newversion only when none exists. A 400 from newversion re-runs that lookup rather than dying.
  * The draft is SYNCED to the manifest by md5 instead of emptied and re-uploaded: files whose Zenodo
    md5 equals the local md5 are kept, files not in the manifest or with a different md5 are deleted,
    and only missing or changed files are uploaded. --fresh restores the delete-everything behaviour.
    --keep-inherited still skips every delete and lists what must be removed by hand.
  * After syncing, the draft's file list is read back and compared to the manifest, name by name and
    md5 by md5, before metadata is set and before publish. A mismatch aborts with the difference.
  * --plan-only does the lookup and prints the sync plan without changing anything on Zenodo.
Auth: the token is read from --token-file and sent only as a Bearer header. It is never printed.
Without --publish the draft is left for review; nothing becomes public.
"""
import argparse, hashlib, json, re, sys, time
from datetime import datetime, timezone
from pathlib import Path
import requests

TIMEOUT = 600


def h(token):
    return {"Authorization": f"Bearer {token}"}


def bail(resp, what, result=None, rpath=None):
    print(f"\nERROR during {what}: HTTP {resp.status_code}", file=sys.stderr)
    try:
        print(json.dumps(resp.json(), indent=2)[:4000], file=sys.stderr)
    except Exception:
        print(resp.text[:2000], file=sys.stderr)
    if result is not None and rpath:
        result["error"] = f"{what}: HTTP {resp.status_code}"
        write_result(result, rpath)
    sys.exit(2)


def write_result(result, rpath):
    result["written_utc"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
    Path(rpath).write_text(json.dumps(result, indent=2) + "\n")
    print(f"wrote {rpath}")


def _digest(p, algo):
    d = hashlib.new(algo)
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            d.update(chunk)
    return d.hexdigest()


def sha256(p):
    return _digest(p, "sha256")


def md5(p):
    return _digest(p, "md5")


def parse_manifest(path):
    files, base = [], path.parent
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        p = Path(line) if Path(line).is_absolute() else (base / line).resolve()
        if not p.exists():
            sys.exit(f"MISSING file in manifest, aborting before any network call: {p}")
        files.append(p)
    names = [p.name for p in files]
    dups = sorted({n for n in names if names.count(n) > 1})
    if dups:
        sys.exit(f"Duplicate basenames (Zenodo lists files flat), aborting: {dups}")
    return files


# ----------------------------------------------------------------------------- draft discovery
def zenodo_md5(f):
    """Zenodo reports file checksums as 'md5:<hex>' (deposit API) or bare hex (records API)."""
    c = f.get("checksum") or ""
    return c.split(":", 1)[1] if ":" in c else c


def find_open_draft(api, token, concept, latest_id):
    """Return the open new-version draft for this concept, or None. GET only."""
    r = requests.get(f"{api}/deposit/depositions/{latest_id}", headers=h(token), timeout=60)
    if r.ok:
        url = (r.json().get("links") or {}).get("latest_draft")
        if url:
            d = requests.get(url, headers=h(token), timeout=60)
            if d.ok and not d.json().get("submitted", False):
                return d.json()
    r = requests.get(f"{api}/deposit/depositions", headers=h(token),
                     params={"status": "draft", "size": 100, "sort": "mostrecent"}, timeout=60)
    if r.ok:
        for d in r.json():
            if str(d.get("conceptrecid")) == str(concept) and not d.get("submitted", False):
                return d
    return None


def get_or_create_draft(api, token, concept, latest_id, result, rpath):
    draft = find_open_draft(api, token, concept, latest_id)
    if draft is not None:
        print(f"Open draft found for concept {concept}: deposition {draft['id']} "
              f"({len(draft.get('files', []))} files). Reusing it; newversion not called.")
        return draft, "reused"
    r = requests.post(f"{api}/deposit/depositions/{latest_id}/actions/newversion",
                      headers=h(token), timeout=120)
    if r.status_code == 400 and "remove all files" in r.text:
        # Zenodo's way of saying a draft with files already exists. Look again, harder.
        print("newversion answered 400 'remove all files first': an open draft exists; looking it up.")
        draft = find_open_draft(api, token, concept, latest_id)
        if draft is None:
            bail(r, "newversion reported an existing draft that the draft lookup could not find; "
                    "open https://zenodo.org/deposit and delete or finish the stray draft", result, rpath)
        return draft, "reused after 400"
    if not r.ok:
        bail(r, "newversion action (403 here usually means the token lacks deposit:actions or is not "
                "the record owner)", result, rpath)
    d = requests.get(r.json()["links"]["latest_draft"], headers=h(token), timeout=60)
    if not d.ok:
        bail(d, "fetch new draft", result, rpath)
    return d.json(), "created"


# ------------------------------------------------------------------------------------ sync plan
def plan_sync(draft_files, manifest, local_md5, fresh=False):
    """Decide keep / delete / upload by basename and md5. Pure function, unit tested."""
    remote = {(f.get("filename") or f.get("key")): f for f in draft_files}
    want = {p.name: p for p in manifest}
    keep, delete, upload = [], [], []
    for name, f in remote.items():
        if fresh or name not in want or zenodo_md5(f) != local_md5[name]:
            delete.append(f)
        else:
            keep.append(name)
    for name, p in want.items():
        if fresh or name not in remote or zenodo_md5(remote[name]) != local_md5[name]:
            upload.append(p)
    return keep, delete, upload


def verify_draft(api, token, dep_id, manifest, local_md5):
    r = requests.get(f"{api}/deposit/depositions/{dep_id}", headers=h(token), timeout=60)
    if not r.ok:
        return False, [f"could not read draft back: HTTP {r.status_code}"], r.json() if r.ok else {}
    d = r.json()
    remote = {(f.get("filename") or f.get("key")): zenodo_md5(f) for f in d.get("files", [])}
    problems = []
    for p in manifest:
        if p.name not in remote:
            problems.append(f"missing on Zenodo: {p.name}")
        elif remote[p.name] != local_md5[p.name]:
            problems.append(f"md5 differs: {p.name} local {local_md5[p.name][:12]} zenodo {remote[p.name][:12]}")
    for name in remote:
        if name not in {p.name for p in manifest}:
            problems.append(f"not in manifest but on Zenodo: {name}")
    return not problems, problems, d


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--token-file", required=True)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--parent-doi", help="concept DOI, e.g. 10.5281/zenodo.21081014")
    g.add_argument("--concept-record-id", help="numeric concept record id, e.g. 21081014")
    ap.add_argument("--expect-latest", help="record id the latest published version must have")
    ap.add_argument("--metadata", required=True)
    ap.add_argument("--files-list", required=True)
    ap.add_argument("--sha256sums", help="SHA256SUMS written by check_deposit.py (basename keyed)")
    ap.add_argument("--result", default="zenodo_dois.json")
    ap.add_argument("--keep-inherited", action="store_true", help="never delete a draft file")
    ap.add_argument("--fresh", action="store_true", help="delete every draft file and re-upload all")
    ap.add_argument("--plan-only", action="store_true", help="look up the draft and print the plan; change nothing")
    ap.add_argument("--sandbox", action="store_true")
    ap.add_argument("--publish", action="store_true")
    a = ap.parse_args()

    if a.parent_doi:
        m = re.fullmatch(r"(?:https?://doi\.org/)?10\.5281/zenodo\.(\d+)", a.parent_doi.strip())
        if not m:
            sys.exit(f"--parent-doi not a Zenodo DOI: {a.parent_doi}")
        concept = m.group(1)
    else:
        concept = a.concept_record_id
    api = "https://sandbox.zenodo.org/api" if a.sandbox else "https://zenodo.org/api"
    meta = json.loads(Path(a.metadata).read_text())
    files = parse_manifest(Path(a.files_list).resolve())
    sums = {}
    if a.sha256sums:
        for ln in Path(a.sha256sums).read_text().splitlines():
            if ln.strip() and not ln.startswith("#"):
                hx, name = ln.split(None, 1)
                sums[name.strip().lstrip("*")] = hx
        for p in files:
            if p.name == Path(a.sha256sums).name:
                continue
            if p.name not in sums:
                sys.exit(f"{p.name} is not in {a.sha256sums}; rerun check_deposit.py")
            if sha256(p) != sums[p.name]:
                sys.exit(f"{p.name} changed since check_deposit.py ran; rerun the gates")
    local_md5 = {p.name: md5(p) for p in files}
    tb = Path(a.token_file).expanduser()
    token = tb.read_text().strip()
    if not token:
        sys.exit(f"token file {tb} is empty")
    result = {"concept_doi": f"10.5281/zenodo.{concept}", "api": api,
              "version": meta["metadata"].get("version"), "manifest_files": len(files),
              "manifest_bytes": sum(p.stat().st_size for p in files), "published": False}
    print(f"Manifest: {len(files)} files, {result['manifest_bytes']:,} bytes. API: {api}")

    # 1) latest published version of the concept
    r = requests.get(f"{api}/records/{concept}/versions/latest", headers=h(token), timeout=60)
    if not r.ok:
        r = requests.get(f"{api}/records/{concept}", headers=h(token), timeout=60)
        if not r.ok:
            bail(r, "resolve concept record", result, a.result)
    latest = r.json()
    latest_id = str(latest["id"])
    lver = (latest.get("metadata") or {}).get("version")
    print(f"Latest published version: record {latest_id}, version {lver}")
    result.update(parent_latest_record=latest_id, parent_latest_version=lver)
    if a.expect_latest and latest_id != str(a.expect_latest):
        print(f"REFUSING: expected latest record {a.expect_latest}, found {latest_id}. "
              "If this version is already published, do not run this again.", file=sys.stderr)
        result["error"] = "latest record mismatch"
        write_result(result, a.result)
        sys.exit(3)

    # 2) find the open draft, or create one
    if a.plan_only:
        draft = find_open_draft(api, token, concept, latest_id)
        if draft is None:
            print("PLAN: no open draft on this concept; a run would call newversion and upload all "
                  f"{len(files)} files.")
            return
        how = "found"
    else:
        draft, how = get_or_create_draft(api, token, concept, latest_id, result, a.result)
    dep_id, bucket = draft["id"], draft["links"]["bucket"]
    if str(draft.get("conceptrecid", concept)) != str(concept):
        sys.exit(f"draft {dep_id} belongs to concept {draft.get('conceptrecid')}, not {concept}; aborting")
    result.update(draft_id=dep_id, edit_url=draft["links"].get("html"), draft_source=how)
    print(f"Draft id: {dep_id} ({how})")

    # 3) sync plan
    keep, delete, upload = plan_sync(draft.get("files", []), files, local_md5, fresh=a.fresh)
    print(f"Sync plan: keep {len(keep)}, delete {len(delete)}, upload {len(upload)}"
          f"{' (--fresh)' if a.fresh else ''}")
    for f in delete:
        print(f"  delete  {f.get('filename') or f.get('key')}")
    for p in upload:
        print(f"  upload  {p.name} ({p.stat().st_size/1e6:.2f} MB)")
    result.update(sync_keep=len(keep), sync_delete=len(delete), sync_upload=len(upload))
    if a.plan_only:
        print("PLAN only. Nothing changed.")
        return
    if a.keep_inherited and delete:
        print(f"--keep-inherited: {len(delete)} files would be deleted and are left in place; "
              "remove them by hand in the browser before publishing:")
        for f in delete:
            print("   ", f.get("filename") or f.get("key"))
        result["remove_by_hand"] = [f.get("filename") or f.get("key") for f in delete]
        delete = []

    # 4) execute
    for f in delete:
        dr = requests.delete(f"{api}/deposit/depositions/{dep_id}/files/{f.get('id')}",
                             headers=h(token), timeout=120)
        if not dr.ok and dr.status_code != 404:
            bail(dr, f"delete {f.get('filename')}", result, a.result)
        print(f"  deleted {f.get('filename') or f.get('key')}")
    for i, p in enumerate(upload, 1):
        if sums and p.name in sums and sha256(p) != sums[p.name]:
            sys.exit(f"{p.name} changed during the run; aborting")
        print(f"  [{i}/{len(upload)}] {p.name} ({p.stat().st_size/1e6:.2f} MB)", flush=True)
        for attempt in (1, 2, 3):
            with p.open("rb") as fp:
                ur = requests.put(f"{bucket}/{p.name}", headers=h(token), data=fp, timeout=TIMEOUT)
            if ur.ok:
                break
            if attempt == 3 or ur.status_code < 500:
                bail(ur, f"upload {p.name}", result, a.result)
            time.sleep(5 * attempt)
    result["uploaded"] = len(upload)

    # 5) read back and verify before anything irreversible
    ok, problems, draft = verify_draft(api, token, dep_id, files, local_md5)
    if not ok:
        print("\nDRAFT DOES NOT MATCH THE MANIFEST. Nothing published.", file=sys.stderr)
        for pr in problems:
            print("  " + pr, file=sys.stderr)
        result["error"] = "draft/manifest mismatch after sync"
        result["problems"] = problems
        write_result(result, a.result)
        sys.exit(4)
    print(f"Verified: {len(files)} files on the draft match the manifest by name and md5.")

    # 6) metadata
    mr = requests.put(f"{api}/deposit/depositions/{dep_id}",
                      headers={**h(token), "Content-Type": "application/json"},
                      json={"metadata": meta["metadata"]}, timeout=120)
    if not mr.ok:
        bail(mr, "set metadata", result, a.result)
    reserved = mr.json().get("metadata", {}).get("prereserve_doi", {}).get("doi")
    result["reserved_version_doi"] = reserved
    print(f"Draft ready. Reserved version DOI: {reserved}")
    print(f"Draft edit URL: {result['edit_url']}")

    if not a.publish:
        print("\nDRAFT only (PUBLISH not set). Review it in the browser before publishing.")
        write_result(result, a.result)
        return
    pr = requests.post(f"{api}/deposit/depositions/{dep_id}/actions/publish", headers=h(token), timeout=300)
    if not pr.ok:
        bail(pr, "publish", result, a.result)
    rec = pr.json()
    result.update(published=True, version_doi=rec.get("doi"), concept_doi_returned=rec.get("conceptdoi"),
                  record_url=rec.get("links", {}).get("record_html"))
    print("\nPUBLISHED.")
    print(f"  Version DOI: {rec.get('doi')}")
    print(f"  Concept DOI (cite this): {rec.get('conceptdoi')}")
    print(f"  Record URL: {result['record_url']}")
    write_result(result, a.result)


if __name__ == "__main__":
    main()
