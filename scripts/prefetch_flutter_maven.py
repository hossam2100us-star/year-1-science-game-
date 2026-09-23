"""Prefetch pinned Flutter jars over HTTPS; validate ZIP CRC and record hashes."""
import concurrent.futures, hashlib, json, subprocess, sys, urllib.request
from pathlib import Path
root=Path(__file__).resolve().parents[1]
version="1.0.0-af7e796e161ae0bb1ff0758c71a7105418bd9ded"
def fetch(module):
    name=f"{module}-{version}.jar"
    url=f"https://storage.googleapis.com/download.flutter.io/io/flutter/{module}/{version}/{name}"
    with urllib.request.urlopen(urllib.request.Request(url,method="HEAD"),timeout=45) as r:
        size=int(r.headers["Content-Length"])
        etag=r.headers.get("ETag")
    output=root/".tools"/name
    subprocess.run([sys.executable,str(root/"scripts/download_tool.py"),url,str(output),str(size),"--workers","8"],check=True,cwd=root)
    data=output.read_bytes()
    return {"module":module,"version":version,"name":name,"sha1":hashlib.sha1(data).hexdigest(),
            "sha256":hashlib.sha256(data).hexdigest(),"etag":etag,"path":str(output),"url":url}
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    rows=list(pool.map(fetch,["arm64_v8a_debug","x86_64_debug"]))
(root/".tools/flutter-maven-prefetch.json").write_text(json.dumps(rows,indent=2))
print("Pinned official Flutter jars downloaded, ZIP CRC checked, hashes recorded.",flush=True)
