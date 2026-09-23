"""Fetch official SDK archives in small resumable HTTPS ranges."""
import argparse, concurrent.futures, hashlib, json, time, urllib.request, zipfile
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument("url"); p.add_argument("output"); p.add_argument("size",type=int); p.add_argument("--sha256"); p.add_argument("--sha1"); p.add_argument("--md5"); p.add_argument("--workers",type=int,default=6)
a=p.parse_args()
root=(Path(__file__).resolve().parents[1]/".tools").resolve()
out=Path(a.output).resolve()
assert out.is_relative_to(root)
parts=out.with_suffix(out.suffix+".chunks-v2"); parts.mkdir(exist_ok=True)
identity={"url":a.url,"size":a.size,"sha256":a.sha256,"sha1":a.sha1,"md5":a.md5}
meta=parts/"source.json"
if meta.exists():
    previous=json.loads(meta.read_text()); previous.setdefault("sha1",None); previous.setdefault("md5",None)
    assert previous==identity
meta.write_text(json.dumps(identity))
chunk=1024*1024
count=(a.size+chunk-1)//chunk
# Reuse complete leading chunks of the same official archive downloaded earlier.
if out.exists() and out.stat().st_size<a.size:
    with out.open("rb") as f:
        for i in range(out.stat().st_size//chunk):
            target=parts/f"{i}.part"
            data=f.read(chunk)
            if not target.exists(): target.write_bytes(data)
def fetch(i):
    start=i*chunk; end=min(a.size-1,start+chunk-1)
    path=parts/f"{i}.part"
    if path.exists() and path.stat().st_size==end-start+1: return
    for attempt in range(4):
        try:
            req=urllib.request.Request(a.url,headers={"Range":f"bytes={start}-{end}","Accept-Encoding":"identity"})
            with urllib.request.urlopen(req,timeout=45) as response:
                assert response.status==206
                assert response.headers["Content-Range"]==f"bytes {start}-{end}/{a.size}"
                data=response.read()
            assert len(data)==end-start+1
            path.write_bytes(data)
            return
        except Exception:
            if attempt==3: raise
            time.sleep(1)
with concurrent.futures.ThreadPoolExecutor(max_workers=a.workers) as pool:
    jobs=[pool.submit(fetch,i) for i in range(count)]
    for done,future in enumerate(concurrent.futures.as_completed(jobs),1):
        future.result()
        if done%10==0 or done==count: print(f"{out.name}: {done}/{count} chunks",flush=True)
staged=out.with_suffix(out.suffix+".assembled")
digest=hashlib.sha256(); digest1=hashlib.sha1(); digestMd5=hashlib.md5()
with staged.open("wb") as f:
    for i in range(count):
        data=(parts/f"{i}.part").read_bytes(); digest.update(data); digest1.update(data); digestMd5.update(data); f.write(data)
if a.sha256: assert digest.hexdigest()==a.sha256.lower(),"Checksum mismatch"
if a.sha1: assert digest1.hexdigest()==a.sha1.lower(),"Checksum mismatch"
if a.md5: assert digestMd5.hexdigest()==a.md5.lower(),"Checksum mismatch"
with zipfile.ZipFile(staged) as z: assert z.testzip() is None
assert staged.is_relative_to(root) and out.is_relative_to(root)
staged.replace(out)
print(f"Verified: {out.name} {digest.hexdigest()}",flush=True)
