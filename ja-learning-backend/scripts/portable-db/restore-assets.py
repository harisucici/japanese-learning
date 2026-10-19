#!/usr/bin/env python3
"""Restore bundled media without a dependency on the original machine paths."""
import hashlib,pathlib,sqlite3,sys
if len(sys.argv)!=3:raise SystemExit('Usage: python3 restore-assets.py learning.sqlite NEW_OUTPUT_DIRECTORY')
file=pathlib.Path(sys.argv[1]);out=pathlib.Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=False)
db=sqlite3.connect(file.resolve().as_uri()+'?mode=ro&immutable=1',uri=True)
for key,asset in db.execute('SELECT path,assetId FROM AssetPath ORDER BY path'):
    relative=pathlib.PurePosixPath(key.lstrip('/'))
    if relative.is_absolute() or '..' in relative.parts:raise RuntimeError('Unsafe asset path')
    target=out.joinpath(*relative.parts);target.parent.mkdir(parents=True,exist_ok=True)
    h=hashlib.sha256()
    with target.open('xb') as dst:
        for (chunk,) in db.execute('SELECT data FROM AssetChunk WHERE assetId=? ORDER BY ordinal',(asset,)):
            h.update(chunk);dst.write(chunk)
    if h.hexdigest()!=asset:raise RuntimeError('Invalid asset '+key)
print('Restored',db.execute('SELECT count(*) FROM AssetPath').fetchone()[0],'files to',out)
