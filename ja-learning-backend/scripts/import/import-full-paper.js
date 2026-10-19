// Import an independently checked complete paper manifest. Does not invent missing content.
require('dotenv').config();
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {PrismaClient}=require('@prisma/client');
const {examSections}=require('../dist/services/exam-rules');
const prisma=new PrismaClient();
async function main(){
 const input=process.argv[2];if(!input)throw Error('Usage: node scripts/import/import-full-paper.js /absolute/path/manifest.json');
 const m=JSON.parse(fs.readFileSync(input,'utf8'));const root=path.dirname(path.resolve(input));
 if(!/^[a-z0-9-]{1,100}$/.test(m.id)||!m.title||!['dated_exam','official_workbook'].includes(m.kind)||!m.reviewedBy||!m.reviewedAt)throw Error('Missing verified source/reviewer metadata');
 if(m.kind==='dated_exam'&&(!Number.isInteger(m.examYear)||m.examYear<2010||m.examYear>new Date().getFullYear()||![7,12].includes(m.examMonth)))throw Error('Dated papers require verified exam year/month');
 const rules=examSections(m.level,m.examYear,m.examMonth);
 if(!Array.isArray(m.sections)||m.sections.length!==rules.length)throw Error('All official test sections are required');
 const ids=[];
 for(let i=0;i<rules.length;i++){
  const section=m.sections[i];
  if(section.id!==rules[i].id||section.minutes!==rules[i].minutes||!section.expectedCount||section.questionIds.length!==section.expectedCount)throw Error(`Section ${i+1} is incomplete or has incorrect timing`);
  if(section.id==='listening'&&!section.audioFiles?.length)throw Error('Missing original listening audio');
  ids.push(...section.questionIds);
 }
 if(new Set(ids).size!==ids.length)throw Error('Duplicate questions');
 if(!m.materials?.length||!m.materials.some(f=>f.role==='question_paper')||!m.materials.some(f=>f.role==='answer_key'))throw Error('Original paper and answer key required');
 for(const f of m.materials){
  const file=path.resolve(root,f.file);if(!fs.existsSync(file))throw Error(`Missing source file ${f.file}`);
  const sha=crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  if(sha!==f.sha256)throw Error(`Checksum mismatch: ${f.file}`);
 }
 for(const s of m.sections)for(const audio of s.audioFiles||[])if(!m.materials.some(f=>f.file===audio&&f.role==='listening_audio'))throw Error('Listening audio is not in the checksum manifest');
 const qs=await prisma.question.findMany({where:{id:{in:ids}}});
 if(qs.length!==ids.length||qs.some(q=>q.level!==m.level||!['pastExam','official'].includes(q.source)||!q.provenance||!(q.options||[]).some(o=>o.id===q.answer)))throw Error('Question/answer/source database validation failed');
 for(const q of qs){const p=q.provenance;if(!p.pdfSha256||!m.materials.some(f=>f.role==='question_paper'&&f.sha256===p.pdfSha256))throw Error('Question source hash does not match original paper material');if(m.kind==='dated_exam'&&(p.examYear!==m.examYear||p.examMonth!==m.examMonth))throw Error('Question provenance does not match the dated exam');}
 for(const section of m.sections){
  const types=new Set(qs.filter(q=>section.questionIds.includes(q.id)).map(q=>q.type));
  const required=section.id==='knowledge_reading'?['grammar','reading']:section.id==='grammar_reading'?['grammar','reading']:section.id==='listening'?['listening']:[];
  if(required.some(t=>!types.has(t)))throw Error(`Missing question types in ${section.id}`);
 }
 const assets=path.join(__dirname,'../data/exam-assets',m.id);fs.mkdirSync(assets,{recursive:true});
 for(const [i,f] of m.materials.entries()){
  const name=`${i}-${path.basename(f.file)}`;fs.copyFileSync(path.resolve(root,f.file),path.join(assets,name));
  f.url=`http://127.0.0.1:${process.env.PORT||3002}/exam-assets/${m.id}/${encodeURIComponent(name)}`;
 }
 for(const s of m.sections)if(s.id==='listening'){
  if(s.audioFiles.length!==1)throw Error('Listening requires one complete original section audio file for continuous timed playback');
  s.audioUrl=m.materials.find(f=>f.file===s.audioFiles[0]).url;
 }
 const data={title:m.title,level:m.level,kind:m.kind,examYear:m.examYear??null,examMonth:m.examMonth??null,ready:true,sections:m.sections,materials:m.materials,verificationNote:`Reviewed by ${m.reviewedBy} at ${m.reviewedAt}; checksums and official timing validated`};
 await prisma.examPaper.upsert({where:{id:m.id},create:{id:m.id,...data},update:data});
 console.log(`Imported verified complete paper: ${m.id}, ${ids.length} questions`);
}
main().catch(e=>{console.error(e.message);process.exitCode=1}).finally(()=>prisma.$disconnect());
