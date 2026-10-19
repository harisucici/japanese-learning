#!/usr/bin/env node
require('dotenv').config();
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),{execFileSync}=require('node:child_process');
const {PrismaClient}=require('@prisma/client');const db=new PrismaClient();
const root=path.resolve(__dirname,'..');
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
(async()=>{
 const materials=await db.studyMaterial.findMany({where:{videoUrl:{not:null},audioUrl:null}});
 const payloadFile=path.join(root,'data/material-fun-library.json');const payload=JSON.parse(fs.readFileSync(payloadFile));
 for(const m of materials){
  const u=new URL(m.videoUrl,'http://localhost');const filename=decodeURIComponent(u.pathname).replace(/^\/study-assets\//,'');
  if(filename.includes('/')||filename.includes('..')||!u.pathname.startsWith('/study-assets/'))throw Error('Unsupported source video path');
  const video=path.join(root,'data/study-assets',filename),audio=path.join(root,'data/study-assets',m.id+'.m4a');
  if(fs.existsSync(audio))execFileSync('afinfo',[audio]);
  else execFileSync('afconvert',[video,audio,'-f','m4af','-d','0']);
  const info=execFileSync('afinfo',[audio],{encoding:'utf8'});const seconds=Number(info.match(/estimated duration:\s*([\d.]+)/)?.[1]);
  if(!seconds||fs.statSync(audio).size===0)throw Error('Invalid extracted audio');
  const audioUrl=new URL(m.id+'.m4a',m.videoUrl).href;
  const metadata={...m.metadata,audioDerivation:{method:'original_audio_packets_copy',sourceVideoSha256:sha(video),audioSha256:sha(audio),format:'audio/mp4',durationSeconds:seconds,tool:'macOS afconvert -f m4af -d 0'}};
  await db.studyMaterial.update({where:{id:m.id},data:{audioUrl,metadata}});
  const record=payload.materials.find(x=>x.id===m.id);if(record){record.audioUrl=audioUrl;record.metadata=metadata;}
  console.log(JSON.stringify({id:m.id,durationSeconds:seconds,audioBytes:fs.statSync(audio).size,audioSha256:sha(audio)}));
 }
 fs.writeFileSync(payloadFile,JSON.stringify(payload,null,2)+'\n');
})().catch(e=>{console.error(e.message);process.exitCode=1}).finally(()=>db.$disconnect());
