#!/usr/bin/env node
// Read-only, repeatable-read PostgreSQL snapshot -> self-contained SQLite bundle.
require('dotenv').config();
const fs=require('node:fs'),path=require('node:path'),os=require('node:os'),crypto=require('node:crypto'),{spawnSync}=require('node:child_process');
const {PrismaClient,Prisma}=require('@prisma/client');
const prisma=new PrismaClient();
const root=path.resolve(__dirname,'..');
const args=process.argv.slice(2);
function option(key,fallback){const i=args.indexOf(key);return i<0?fallback:args[i+1];}
const out=path.resolve(option('--out',path.join(root,'data/portable-export',new Date().toISOString().replace(/[:.]/g,'-'))));
const python=option('--python',process.env.PYTHON||'python3');
function portable(value){
 if(typeof value==='string'){try{const u=new URL(value);if(['localhost','127.0.0.1','[::1]'].includes(u.hostname)&&/^\/(study-assets|exam-assets)\//.test(u.pathname))return u.pathname;}catch{}return value;}
 if(Array.isArray(value))return value.map(portable);
 if(value&&typeof value==='object'&&!(value instanceof Date))return Object.fromEntries(Object.entries(value).filter(([k])=>k!=='sourcePath').map(([k,v])=>[k,portable(v)]));
 return value;
}
(async()=>{
 if(fs.existsSync(out))throw Error('Output directory already exists; use a new --out directory.');
 const models=Prisma.dmmf.datamodel.models;
 const snapshot=await prisma.$transaction(async tx=>{
  const tables={};for(const m of models){const accessor=m.name[0].toLowerCase()+m.name.slice(1);tables[m.name]=(await tx[accessor].findMany({orderBy:{id:'asc'}})).map(portable);}
  return {formatVersion:1,createdAt:new Date().toISOString(),schemaSha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'prisma/schema.prisma'))).digest('hex'),models,enums:Prisma.dmmf.datamodel.enums,tables};
 },{isolationLevel:'RepeatableRead',timeout:60000});
 fs.mkdirSync(out,{recursive:true,mode:0o700});
 const scratch=fs.mkdtempSync(path.join(os.tmpdir(),'japanese-portable-'));const snapshotFile=path.join(scratch,'snapshot.json');
 try{
  fs.writeFileSync(snapshotFile,JSON.stringify(snapshot),{mode:0o600});
  const r=spawnSync(python,[path.join(__dirname,'portable-db/build.py'),snapshotFile,out,root],{stdio:'inherit'});
  if(r.error)throw r.error;if(r.status!==0)throw Error(`SQLite export failed (${r.status}); incomplete output is marked by absence of manifest.json.`);
 }finally{fs.rmSync(scratch,{recursive:true,force:true});}
 console.log(`Portable database ready: ${out}`);
})().catch(e=>{console.error(e.message);process.exitCode=1}).finally(()=>prisma.$disconnect());
