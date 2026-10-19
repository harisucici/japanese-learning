#!/usr/bin/env python3
"""No third-party dependencies. Preserve source rows, embed files in 64 KiB chunks."""
import hashlib,json,mimetypes,pathlib,sqlite3,sys,urllib.parse,shutil
snapshot_path,out,root=map(pathlib.Path,sys.argv[1:])
snapshot=json.loads(snapshot_path.read_text());db_path=out/'learning.sqlite'
if db_path.exists(): raise RuntimeError('Refusing to replace an existing database')
db=sqlite3.connect(db_path);db.execute('PRAGMA journal_mode=WAL');db.execute('PRAGMA foreign_keys=ON')
def q(v):return '"'+v.replace('"','""')+'"'
def compact(v):return json.dumps(v,ensure_ascii=False,separators=(',',':'))
def insert(table,row):
    db.execute('INSERT INTO '+q(table)+' ('+','.join(map(q,row))+') VALUES ('+','.join('?' for _ in row)+')',list(row.values()))
enums={e['name']:[v['name'] for v in e['values']] for e in snapshot['enums']}
def literal(s):return "'"+s.replace("'","''")+"'"
ddl=[]
for model in snapshot['models']:
    columns=[]
    for f in model['fields']:
        if f['kind']=='object':continue
        name=q(f['name']);typ='TEXT'
        if not f['isList']:
            typ={'Int':'INTEGER','BigInt':'INTEGER','Boolean':'INTEGER','Float':'REAL','Bytes':'BLOB'}.get(f['type'],'TEXT')
        definition=name+' '+typ
        if f.get('isId'):definition+=' PRIMARY KEY'
        if f['isRequired']:definition+=' NOT NULL'
        if f.get('isUnique'):definition+=' UNIQUE'
        if f['isList'] or f['type']=='Json':definition+=' CHECK ('+name+' IS NULL OR json_valid('+name+'))'
        if f['type']=='Boolean':definition+=' CHECK ('+name+' IN (0,1))'
        if f['kind']=='enum':definition+=' CHECK ('+name+' IN ('+','.join(map(literal,enums[f['type']]))+'))'
        columns.append(definition)
    for fields in model.get('uniqueFields',[]):columns.append('UNIQUE ('+','.join(map(q,fields))+')')
    for f in model['fields']:
        if f.get('relationFromFields'):
            columns.append('FOREIGN KEY ('+','.join(map(q,f['relationFromFields']))+') REFERENCES '+q(f['type'])+' ('+','.join(map(q,f['relationToFields']))+') DEFERRABLE INITIALLY DEFERRED')
    if model['name']=='Explanation':columns.append('FOREIGN KEY ("questionId") REFERENCES "Question"("id") DEFERRABLE INITIALLY DEFERRED')
    if model['name']=='Question':columns.append('FOREIGN KEY ("explanationId") REFERENCES "Explanation"("id") DEFERRABLE INITIALLY DEFERRED')
    ddl.append('CREATE TABLE '+q(model['name'])+' (\n '+',\n '.join(columns)+'\n);')
extra='''
CREATE TABLE ExportMetadata (key TEXT PRIMARY KEY,value TEXT NOT NULL);
CREATE TABLE Asset (id TEXT PRIMARY KEY,sha256 TEXT NOT NULL UNIQUE,byteLength INTEGER NOT NULL CHECK(byteLength>=0),mimeType TEXT NOT NULL,chunkCount INTEGER NOT NULL CHECK(chunkCount>0));
CREATE TABLE AssetChunk (assetId TEXT NOT NULL REFERENCES Asset(id),ordinal INTEGER NOT NULL CHECK(ordinal>=0),data BLOB NOT NULL CHECK(length(data)<=65536),PRIMARY KEY(assetId,ordinal));
CREATE TABLE AssetPath (path TEXT PRIMARY KEY,assetId TEXT NOT NULL REFERENCES Asset(id));
CREATE TABLE AssetReference (ownerTable TEXT NOT NULL,ownerId TEXT NOT NULL,jsonPointer TEXT NOT NULL,uri TEXT NOT NULL,assetId TEXT REFERENCES Asset(id),PRIMARY KEY(ownerTable,ownerId,jsonPointer));
CREATE INDEX asset_reference_owner ON AssetReference(ownerTable,ownerId);
CREATE INDEX question_catalog ON Question(source,level,type,"order");
CREATE INDEX material_collection ON StudyMaterial(collection,filename);
CREATE INDEX session_user_date ON LearningSession(userId,createdAt);
CREATE INDEX answer_session ON LearningAnswer(sessionId);
CREATE INDEX record_user_date ON ExamRecord(userId,completedAt);
CREATE INDEX review_user_date ON ReviewItem(userId,nextReviewAt);
CREATE VIEW QuestionOption AS SELECT q.id AS questionId, CAST(j.key AS INTEGER) AS position,json_extract(j.value,'$.id') AS id,json_extract(j.value,'$.content') AS content,j.value AS optionJson FROM Question q,json_each(q.options) j;
CREATE VIEW QuestionTag AS SELECT q.id AS questionId,CAST(j.key AS INTEGER) AS position,j.value AS tag FROM Question q,json_each(q.tags) j;
CREATE VIEW FunPaperQuestion AS SELECT p.id AS paperId,CAST(j.key AS INTEGER) AS position,j.value AS questionId FROM FunPaper p,json_each(p.questionIds) j;
CREATE VIEW FunPaperMaterial AS SELECT p.id AS paperId,CAST(j.key AS INTEGER) AS position,j.value AS materialId FROM FunPaper p,json_each(p.materialIds) j;
CREATE VIEW SessionQuestion AS SELECT p.id AS sessionId,CAST(j.key AS INTEGER) AS position,j.value AS questionId FROM LearningSession p,json_each(p.questionIds) j;
CREATE VIEW RecordQuestion AS SELECT p.id AS recordId,CAST(j.key AS INTEGER) AS position,j.value AS questionId FROM ExamRecord p,json_each(p.questionIds) j;
CREATE VIEW ExamSection AS SELECT p.id AS paperId,CAST(j.key AS INTEGER) AS position,json_extract(j.value,'$.id') AS sectionId,json_extract(j.value,'$.title') AS title,json_extract(j.value,'$.minutes') AS minutes,j.value AS sectionJson FROM ExamPaper p,json_each(p.sections) j;
CREATE VIEW ExamSectionQuestion AS SELECT s.paperId,s.sectionId,CAST(j.key AS INTEGER) AS position,j.value AS questionId FROM ExamSection s,json_each(s.sectionJson,'$.questionIds') j;
'''
schema='PRAGMA foreign_keys=ON;\n'+'\n'.join(ddl)+'\n'+extra
db.executescript(schema);(out/'schema.sql').write_text(schema)
db.execute('BEGIN')
source_hashes={}
for m in snapshot['models']:
    source_rows=[]
    fields={f['name']:f for f in m['fields'] if f['kind']!='object'}
    for original in snapshot['tables'][m['name']]:
        row={}
        for key,f in fields.items():
            value=original[key]
            row[key]=compact(value) if value is not None and (f['isList'] or f['type']=='Json') else int(value) if isinstance(value,bool) else float(value) if value is not None and f['type']=='Float' else value
        insert(m['name'],row)
        source_rows.append(list(row.values()))
    source_hashes[m['name']]=hashlib.sha256(json.dumps(source_rows,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()
# Embed original files by hash, deduplicating identical content; paths are server-independent.
asset_paths={};assets={}
for relative,prefix in [('data/study-assets','/study-assets/'),('data/exam-assets','/exam-assets/'),('data/official/pdf','/official-assets/')]:
    folder=root/relative
    if not folder.exists():continue
    for file in sorted(folder.rglob('*')):
        if not file.is_file():continue
        sha=hashlib.sha256(file.read_bytes()).hexdigest();size=file.stat().st_size
        if not size:raise RuntimeError('Empty asset: '+str(file))
        if sha not in assets:
            count=(size+65535)//65536
            insert('Asset',dict(id=sha,sha256=sha,byteLength=size,mimeType=mimetypes.guess_type(file.name)[0] or 'application/octet-stream',chunkCount=count))
            with file.open('rb') as src:
                for ordinal in range(count):insert('AssetChunk',dict(assetId=sha,ordinal=ordinal,data=src.read(65536)))
            assets[sha]=size
        key=prefix+file.relative_to(folder).as_posix();asset_paths[key]=sha
        insert('AssetPath',dict(path=key,assetId=sha))
def walk(value,pointer=''):
    if isinstance(value,dict):
        for k,v in value.items():yield from walk(v,pointer+'/'+k.replace('~','~0').replace('/','~1'))
    elif isinstance(value,list):
        for k,v in enumerate(value):yield from walk(v,pointer+'/'+str(k))
    elif isinstance(value,str) and (value.startswith(('http://','https://','/study-assets/','/exam-assets/','/official-assets/'))):yield pointer,value
for table,rows in snapshot['tables'].items():
    for row in rows:
        for pointer,uri in walk(row):
            parsed=urllib.parse.urlparse(uri);key=urllib.parse.unquote(parsed.path)
            if parsed.hostname in ('www.jlpt.jp','jlpt.jp') and key.startswith('/samples/'):
                key='/official-assets/'+pathlib.PurePosixPath(key).name
            asset=asset_paths.get(key) if not parsed.hostname or parsed.hostname in ('www.jlpt.jp','jlpt.jp','localhost','127.0.0.1') else None
            if uri.startswith(('/study-assets/','/exam-assets/','/official-assets/')) and not asset:raise RuntimeError('Missing local asset '+uri)
            insert('AssetReference',dict(ownerTable=table,ownerId=row['id'],jsonPointer=pointer,uri=uri,assetId=asset))
        if table=='StudyMaterial' and asset_paths.get(row['fileUrl'])!=row['sha256']:raise RuntimeError('PDF checksum mismatch: '+row['id'])
        if table=='Question' and isinstance(row.get('provenance'),dict):
            p=row['provenance'];url=p.get('sourceUrl');expected=p.get('pdfSha256')
            if url and expected:
                ref=db.execute('SELECT assetId FROM AssetReference WHERE ownerTable=? AND ownerId=? AND jsonPointer=?',(table,row['id'],'/provenance/sourceUrl')).fetchone()
                if not ref or ref[0]!=expected:raise RuntimeError('Question source checksum mismatch: '+row['id'])
for key,value in dict(formatVersion=1,createdAt=snapshot['createdAt'],sourceSchemaSha256=snapshot['schemaSha256'],jsonStorage='UTF-8 JSON TEXT',dateStorage='ISO-8601 UTC TEXT',booleanStorage='INTEGER 0/1',assetStorage='SHA256 deduplicated 64KiB BLOB chunks',personalDataIncluded=True).items():
    insert('ExportMetadata',dict(key=key,value=compact(value)))
assert not db.execute('PRAGMA foreign_key_check').fetchall()
db.commit();assert db.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
# Reusable source mapping, including JSON/list/enums for a future runtime adapter.
(out/'source-models.json').write_text(compact(dict(models=snapshot['models'],enums=snapshot['enums'])))
counts={name:db.execute('SELECT count(*) FROM '+q(name)).fetchone()[0] for name in snapshot['tables']}
counts.update({name:db.execute('SELECT count(*) FROM '+q(name)).fetchone()[0] for name in ['Asset','AssetPath','AssetChunk','AssetReference']})
# SQL dump is independently importable by SQLite/libSQL; BLOB chunks stay under statement-size limits.
with (out/'learning.sql').open('w') as f:
    for line in db.iterdump():f.write(line+'\n')
row_hashes={name:hashlib.sha256(json.dumps(db.execute('SELECT * FROM '+q(name)+' ORDER BY id').fetchall(),ensure_ascii=False,separators=(',',':')).encode()).hexdigest() for name in snapshot['tables']}
assert row_hashes==source_hashes, 'SQLite rows differ from PostgreSQL snapshot'
db.execute('PRAGMA wal_checkpoint(TRUNCATE)')
db.close()
for filename in ['README.md','import-turso.sh','verify.py']:
    shutil.copyfile(pathlib.Path(__file__).with_name(filename),out/filename)
shutil.copyfile(pathlib.Path(__file__).with_name('restore-assets.py'),out/'restore-assets.py')
readonly=sqlite3.connect(db_path.resolve().as_uri()+'?mode=ro&immutable=1',uri=True)
remote_count=readonly.execute('SELECT count(*) FROM AssetReference WHERE assetId IS NULL').fetchone()[0];readonly.close()
manifest=dict(rowHashes=row_hashes,formatVersion=1,createdAt=snapshot['createdAt'],counts=counts,assetBytes=sum(assets.values()),databaseSha256=hashlib.sha256(db_path.read_bytes()).hexdigest(),personalDataIncluded=True,remoteOnlyReferences=remote_count)
(out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print(json.dumps(dict(counts=counts,assetBytes=manifest['assetBytes']),ensure_ascii=False))
