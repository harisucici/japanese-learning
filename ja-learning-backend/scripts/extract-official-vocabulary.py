import pdfplumber,re,json,hashlib,unicodedata,collections
from pathlib import Path
import argparse
parser=argparse.ArgumentParser();parser.add_argument('--pdf-dir',default='data/official/pdf');parser.add_argument('--output-dir',default='data/official');args=parser.parse_args()
OUT=Path(args.output_dir);OUT.mkdir(parents=True,exist_ok=True)
ROOT=Path(args.pdf_dir); questions=[];explanations=[];skipped=[];audit=[]
def lines(chars,page,underline=False):
 groups=[]
 for c in sorted(chars,key=lambda c:(round(c['top']/3),c['x0'])):
  if not groups or abs(groups[-1][0]['top']-c['top'])>3:groups.append([])
  groups[-1].append(c)
 out=[]
 for group in groups:
  group.sort(key=lambda c:c['x0']);s='';prev=None;mark=False
  for c in group:
   under=underline and any(abs(l['top']-c['bottom'])<5 and l['x0']<=c['x0']+2 and l['x1']>=c['x1']-2 and l['width']>5 for l in page.lines)
   if under!=mark:s+='【' if under else '】';mark=under
   if prev and c['x0']-prev['x1']>c['size']*.45:s+=' '
   s+=c['text'];prev=c
  if mark:s+='】'
  out.append(s.strip())
 return '\n'.join(out)
for n in range(1,6):
 level=f'n{n}';vocab_groups={1:4,2:6,3:5,4:5,5:4}[n]
 with pdfplumber.open(ROOT/f'N{n}answer.pdf') as a:
  tables=a.pages[0].extract_tables()[:vocab_groups];answers={};group_for={}
  for gi,t in enumerate(tables,1):
   for ri in range(0,len(t)-1,2):
    for num,ans in zip(t[ri],t[ri+1]):
     if num and ans and num.isdigit() and ans in ['1','2','3','4']:
      assert int(num) not in answers;answers[int(num)]=int(ans);group_for[int(num)]=gi
 assert sorted(answers)==list(range(1,max(answers)+1))
 qsize=9.2 if n<4 else (11.3 if n==4 else 12.8);body=11.5 if n<4 else (12.8 if n==4 else 14.2)
 with pdfplumber.open(ROOT/f'N{n}V.pdf') as doc:
  qnum=0
  for pi,p in enumerate(doc.pages):
   if pi<2:continue
   p=p.dedupe_chars();raw=[c for c in p.chars if c['text'].startswith('(cid:') and c['x0']<90 and abs(c['size']-qsize)<.2]
   marks=[]
   for c in sorted(raw,key=lambda c:(c['top'],c['x0'])):
    if not marks or abs(marks[-1]['top']-c['top'])>3:marks.append(c)
   for mi,m in enumerate(marks):
    qnum+=1;end=marks[mi+1]['top']-12 if mi+1<len(marks) else p.height-60
    headings=[c['top'] for c in p.chars if c['top']>m['top']+20 and c['size']>=16 and c['x0']<130]
    if headings:end=min(end,min(headings)-6)
    cs=[dict(c) for c in p.chars if m['top']-9<=c['top']<end and c['x0']>=40 and c['x1']<540 and c['size']>=body-.3 and c['size']<body+1]
    # Option numerals are either Unicode fullwidth digits or official font glyphs.
    if n>=4:
     opts=[c for c in cs if c['text'].startswith('(cid:')]
     starts=opts[-4:] if len(opts)>=4 else []
    else:
     opts=[]
     for c in cs:
      if c['text'] not in '１２３４':continue
      right=[v for v in cs if abs(v['top']-c['top'])<3 and v['x0']>c['x0']+.1]
      if right and min(v['x0'] for v in right)-c['x1']>2:opts.append(c)
     starts=[]
     for oi in range(len(opts)-3):
      seq=opts[oi:oi+4]
      vals=[int(unicodedata.normalize('NFKC',c['text'])) for c in seq]
      if vals==[1,2,3,4]:starts=seq
    why=None
    if not starts:why='four ordered options not found'
    if why:skipped.append(dict(level=level,number=qnum,reason=why));continue
    stemcs=[c for c in cs if c['top']<starts[0]['top']-3]
    stem=lines(stemcs,p,True)
    manual_stems={(4,22):'わたしの むすこは、１年で ５（ ）くらい せが 高く なりました。',(4,23):'お店で ３だいの パソコンを （ ）、いちばん かるい パソコンを えらびました。',(5,21):'わたしの へやは この アパートの ２（ ）です。'}
    if (n,qnum) in manual_stems:stem=manual_stems[(n,qnum)]
    content_opts=[]
    for oi,start in enumerate(starts):
     nextstart=starts[oi+1] if oi<3 else None
     chosen=[]
     for c in cs:
      if c in starts:continue
      # reading order: line first, then column within a line
      after=c['top']>start['top']+5 or (abs(c['top']-start['top'])<=5 and c['x0']>start['x0'])
      before=not nextstart or c['top']<nextstart['top']-5 or (abs(c['top']-nextstart['top'])<=5 and c['x0']<nextstart['x0'])
      if after and before:chosen.append(c)
     content_opts.append(lines(chosen,p))
    texts=[stem]+content_opts
    if any('(cid:' in t or not t.strip() for t in texts):skipped.append(dict(level=level,number=qnum,reason='unmapped glyph or empty field'));continue
    # The last question on a page can be followed by another instruction heading.
    if any('問題１' in t or '問題２' in t or 'もんだい' in t or 'えらんで' in t for t in texts):skipped.append(dict(level=level,number=qnum,reason='heading overlap'));continue
    qid=f'jlpt-2018-{level}-v-{qnum:03}';eid=qid+'-explanation'
    meta=dict(publicationYear=2018,examYear=None,workbook='Official Practice Workbook Vol. 2',sourceUrl=f'https://www.jlpt.jp/samples/sample2018/pdf/N{n}V.pdf',answerUrl=f'https://www.jlpt.jp/samples/sample2018/pdf/N{n}answer.pdf',pdfPage=pi+1,section='vocabulary',group=group_for[qnum],number=qnum,correctOption=answers[qnum],verification='official_text_and_answer_table',manualGlyphReview=(n,qnum) in manual_stems,usage='local_personal_study',pdfSha256=hashlib.sha256((ROOT/f'N{n}V.pdf').read_bytes()).hexdigest())
    options=[dict(id=f'{qid}-o{i+1}',content=t,index=i) for i,t in enumerate(content_opts)]
    tasks={1:['选择【】部分的正确读音。','选择最合适的选项填空。','选择与【】部分意思最接近的选项。','选择词语用法正确的句子。'],2:['选择【】部分的正确读音。','选择【】部分的正确写法。','选择最合适的选项填空。','选择最合适的选项填空。','选择与【】部分意思最接近的选项。','选择词语用法正确的句子。'],3:['选择【】部分的正确读音。','选择【】部分的正确写法。','选择最合适的选项填空。','选择与【】部分意思最接近的选项。','选择词语用法正确的句子。'],4:['选择【】部分的正确读音。','选择【】部分的正确写法。','选择最合适的选项填空。','选择与【】部分意思最接近的选项。','选择词语用法正确的句子。'],5:['选择【】部分的正确读音。','选择【】部分的正确写法。','选择最合适的选项填空。','选择与【】部分意思最接近的选项。']}
    stem=tasks[n][group_for[qnum]-1]+'\n'+stem
    question=dict(id=qid,level=level,type='kanji' if group_for[qnum]==1 else 'vocabulary',content=stem,options=options,answer=options[answers[qnum]-1]['id'],source='pastExam',explanationId=eid,tags=['JLPT官方问题集','出版年份:2018','仅限本机个人学习',f'大题:{group_for[qnum]}',f'题号:{qnum}',f'来源:{meta["sourceUrl"]}'],order=qnum,provenance=meta)
    questions.append(question);explanations.append(dict(id=eid,questionId=qid,translation='',wordAnalysis=[],sentenceStructure='',grammar=[],optionAnalysis=[],extensions=[],note=f'官方标准答案：选项 {answers[qnum]}。本题来自2018年出版的官方问题集第二集，非2018年某场完整试卷。中文解析尚未编写。出处：{meta["sourceUrl"]} PDF第{pi+1}页；答案：{meta["answerUrl"]}。'))
    audit.append(dict(id=qid,**meta))
  assert qnum==len(answers),(level,qnum,len(answers))
(OUT/'jlpt-2018-vocabulary.json').write_text(json.dumps(dict(questions=questions,explanations=explanations),ensure_ascii=False,indent=2))
(OUT/'audit.json').write_text(json.dumps(dict(importable=len(questions),byLevel=dict(collections.Counter(q['level'] for q in questions)),skipped=skipped,items=audit),ensure_ascii=False,indent=2))
print('accepted',len(questions),'by level',collections.Counter(q['level'] for q in questions),'skipped',skipped)
for q in questions[::max(1,len(questions)//8)]: print(q['id'],q['content'],q['options'])
