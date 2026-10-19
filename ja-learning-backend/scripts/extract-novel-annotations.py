from pathlib import Path
import pdfplumber,json,re
source=Path('/Volumes/Mac Data/Documents/看知乎小说背日语N1词汇.pdf')
lessons=json.loads(Path('/Volumes/Mac Data/Documents/StudioProjects/ja-learning-backend/data/novel-lessons.json').read_text())['lessons']
def boxes(p):
 result=[]
 for r in p.rects:
  col=r.get('non_stroking_color')
  if not isinstance(col,(tuple,list)) or len(col)!=3 or min(col)>.96 or max(col)<.2:continue
  chars=[c for c in p.chars if c['size']<25 and c['x0']>=r['x0']-1 and c['x1']<=r['x1']+1 and c['top']>=r['top']-2 and c['bottom']<=r['bottom']+2]
  text=''.join(c['text'] for c in chars).strip()
  result.append(dict(text=text,x0=r['x0'],x1=r['x1'],top=r['top']))
 return result
with pdfplumber.open(source) as d:
 lex=set()
 for l in lessons[:12]:
  for pg in l['pages']:
   if not pg['recall']:continue
   bs=boxes(d.pages[pg['number']-1]);groups=[]
   for b in bs:
    if groups:
     prev=groups[-1][-1]
     same=abs(prev['top']-b['top'])<2 and abs(prev['x1']-b['x0'])<2
     wrap=prev['x1']>490 and b['x0']<100 and 20<b['top']-prev['top']<40
     if same or wrap:groups[-1].append(b);continue
    groups.append([b])
   for g in groups:
    raw=''.join(b['text'] for b in g)
    for word in re.findall(r'([一-龥々ぁ-ゖァ-ヺー]+)[（(]',raw):lex.add(word)
 lex.update('途切れ途切れ 呆れる 発見 沸く 這う 果たして 絶叫 辺縁 ばつが悪い 飼料 寄りかかる'.split())
 print('lex',len(lex))
 annotations=[]
 for l in lessons[:12]:
  for pg in l['pages']:
   if pg['recall']:continue
   bs=boxes(d.pages[pg['number']-1]);groups=[]
   for b in bs:
    if not b['text']:continue
    if groups:
     prev=groups[-1][-1]
     same=abs(prev['top']-b['top'])<2 and abs(prev['x1']-b['x0'])<2
     wrap=prev['x1']>500 and b['x0']<95 and 20<b['top']-prev['top']<40
     if same or wrap:groups[-1].append(b);continue
    groups.append([b])
   for g in groups:
    raw=''.join(b['text'] for b in g)
    candidates=[w for w in lex if raw.startswith(w)]
    if not candidates:continue
    word=max(candidates,key=len);rest=raw[len(word):];m=re.match('[ぁ-ゖー]*',rest);reading=m.group();meaning=rest[len(reading):]
    if not meaning or not re.search('[一-龥]',meaning) or re.search('[ぁ-ゖァ-ヺ]',meaning):continue
    if re.search('[一-龥]',word) and not reading:continue
    if len(meaning)>14 or len(word)>18:continue
    if raw not in ''.join(pg['text'].split()):continue
    annotations.append(dict(page=pg['number'],raw=raw,word=word,reading=reading,meaning=meaning))
(Path(__file__).resolve().parents[1]/'data/novel-annotations.json').write_text(json.dumps(annotations,ensure_ascii=False,indent=2))
print('annotations',len(annotations))

