"""Populate the verified Gradle distribution cache without downloading twice."""
import hashlib, zipfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
url="https://services.gradle.org/distributions/gradle-9.3.1-bin.zip"
checksum="b266d5ff6b90eada6dc3b20cb090e3731302e553a27c5d3e4df1f0d76beaff06"
archive=root/".tools/gradle.zip"
assert hashlib.sha256(archive.read_bytes()).hexdigest()==checksum
n=int.from_bytes(hashlib.md5(url.encode()).digest(),"big")
digits="0123456789abcdefghijklmnopqrstuvwxyz"; key=""
while n: n,r=divmod(n,36); key=digits[r]+key
cache=root/".tools/gradle/wrapper/dists/gradle-9.3.1-bin"/key
cache.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(archive) as z:
    for name in z.namelist():
        assert (cache/name).resolve().is_relative_to(cache.resolve())
    z.extractall(cache)
(cache/"gradle-9.3.1-bin.zip.ok").touch()
properties=root/"android/gradle/wrapper/gradle-wrapper.properties"
properties.write_text("distributionBase=GRADLE_USER_HOME\ndistributionPath=wrapper/dists\nzipStoreBase=GRADLE_USER_HOME\nzipStorePath=wrapper/dists\ndistributionUrl=https\\://services.gradle.org/distributions/gradle-9.3.1-bin.zip\ndistributionSha256Sum="+checksum+"\n")
print("Verified Gradle wrapper cache ready.")
