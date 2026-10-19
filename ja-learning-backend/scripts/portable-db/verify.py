#!/usr/bin/env python3
"""Read-only verification: python3 verify.py learning.sqlite [manifest.json]."""
import hashlib,json,pathlib,sqlite3,sys
file=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else pathlib.Path(__file__).with_name('learning.sqlite'))
manifest_path=pathlib.Path(sys.argv[2]) if len(sys.argv)>2 else file.with_name('manifest.json')
manifest=json.loads(manifest_path.read_text()) if manifest_path.exists() else None
db=sqlite3.connect(file.resolve().as_uri()+'?mode=ro&immutable=1',uri=True)
def ensure(condition,message):
    if not condition:raise RuntimeError(message)
ensure(db.execute('PRAGMA integrity_check').fetchone()[0]=='ok','SQLite integrity check failed')
ensure(not db.execute('PRAGMA foreign_key_check').fetchall(),'Broken foreign keys')
for view,field,target in [('FunPaperQuestion','questionId','Question'),('FunPaperMaterial','materialId','StudyMaterial'),('SessionQuestion','questionId','Question'),('RecordQuestion','questionId','Question'),('ExamSectionQuestion','questionId','Question')]:
    ensure(db.execute(f'SELECT count(*) FROM "{view}" v LEFT JOIN "{target}" t ON t.id=v."{field}" WHERE t.id IS NULL').fetchone()[0]==0,'Broken relationship '+view)
ensure(db.execute('SELECT count(*) FROM Question q WHERE NOT EXISTS (SELECT 1 FROM QuestionOption o WHERE o.questionId=q.id AND o.id=q.answer)').fetchone()[0]==0,'Invalid answer option')
ensure(db.execute('SELECT count(*) FROM Question q JOIN Explanation e ON e.id=q.explanationId WHERE e.questionId<>q.id').fetchone()[0]==0,'Mismatched explanation')
ensure(db.execute('SELECT count(*) FROM LearningSession s LEFT JOIN FunPaper p ON p.id=s.collectionId WHERE s.collectionId IS NOT NULL AND p.id IS NULL').fetchone()[0]==0,'Broken session paper')
for qid,source,provenance in db.execute('SELECT id,source,provenance FROM Question'):
    if provenance:
        p=json.loads(provenance)
        if p.get('kind')=='user_material':ensure(p['supportingQuote'] in p['passage'],'Source quote mismatch '+qid)
for row in db.execute('SELECT id,sha256,byteLength,chunkCount FROM Asset'):
    asset,sha,size,count=row;h=hashlib.sha256();length=0;seen=0
    for ordinal,data in db.execute('SELECT ordinal,data FROM AssetChunk WHERE assetId=? ORDER BY ordinal',(asset,)):
        ensure(ordinal==seen,'Noncontiguous asset chunks '+asset);h.update(data);length+=len(data);seen+=1
    ensure(h.hexdigest()==sha and length==size and seen==count,'Asset checksum mismatch '+asset)
for mid,url,sha in db.execute('SELECT id,fileUrl,sha256 FROM StudyMaterial'):
    found=db.execute('SELECT assetId FROM AssetPath WHERE path=?',(url,)).fetchone()
    ensure(found and found[0]==sha,'Missing material PDF '+mid)
ensure(db.execute("SELECT count(*) FROM AssetReference WHERE uri LIKE '/study-assets/%' AND assetId IS NULL").fetchone()[0]==0,'Unresolved local media')
for table in ['Question','StudyMaterial','ExamPaper','FunPaper']:
    ensure(db.execute(f'''SELECT count(*) FROM "{table}" WHERE instr(CAST("id" AS TEXT),'/Volumes/')>0''').fetchone()[0]==0,'Absolute primary key')
if manifest:
    ensure(hashlib.sha256(file.read_bytes()).hexdigest()==manifest['databaseSha256'],'Database file checksum mismatch')
    for table,count in manifest['counts'].items():ensure(db.execute('SELECT count(*) FROM "'+table+'"').fetchone()[0]==count,'Row count mismatch '+table)
    for table,expected in manifest.get('rowHashes',{}).items():
        rows=db.execute('SELECT * FROM "'+table+'" ORDER BY id').fetchall()
        actual=hashlib.sha256(json.dumps(rows,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()
        ensure(actual==expected,'Source row mismatch '+table)
print(json.dumps({'ok':True,'questions':db.execute('SELECT count(*) FROM Question').fetchone()[0],'materials':db.execute('SELECT count(*) FROM StudyMaterial').fetchone()[0],'assets':db.execute('SELECT count(*) FROM Asset').fetchone()[0],'checks':['integrity','foreign_keys','question_options','explanations','paper_membership','source_quotes','all_asset_bytes','manifest_counts','source_row_hashes']},ensure_ascii=False))
db.close()
