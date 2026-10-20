from pathlib import Path
import json,hashlib,re,random
import pdfplumber
backend=Path('/Volumes/Mac Data/Documents/StudioProjects/ja-learning-backend');assets=backend/'data/study-assets'
pdf=Path('/Volumes/Mac Data/Documents/看知乎小说背日语N1词汇.pdf');digest=hashlib.sha256(pdf.read_bytes()).hexdigest();mid='novel-'+digest[:12]
starts=[2,12,20,30,41,55,72,91,117,149,192,242,281,282,283,284,285,286,287,288,289,290,291,292,294,295,296,297]
titles=['校草的粉红小鸡','当我穿进虐文里当沙雕女主','家族破产后，送外卖遇上前男友','惊！世子爷竟是女儿身','死后的第101天','醒来时校霸的裤衩子挂在我的裤腰带上','当了三年金丝雀后，金主的未婚妻回国了','当痔疮手术遇上清冷男神','极寒末世，我在3000㎡的仓储超市里吃烧烤','和死对头上恋综亲嘴被全网直播了','我爸是省委书记，而我却在街道办当小科员','装了三年清纯小白花后，被豪门老公读心了','恋爱脑的觉醒','让人着迷的男大','我与青梅竹马死对头的爱恨情仇','校园三人修罗场','抛弃金主，清醒影后要出逃','安小鸟的阴谋','无法挽回的恋人','大小姐落难记','霸总白月光在线要钱','霸总夫人的夜店丑闻','诡计多端的男同','闺蜜的阴谋','陆少的小娇妻','痴情女二清醒后要离婚','玩弄权势的太后','震惊全校之校草爱上我']
# Long-form exercises test literal source recall, avoiding unreliable dictionary/grade claims.
words='受験 紹介 責任者 正常 意識 不便 執筆 接触 収集 証拠 出張 処理 雰囲気 複雑 受付 解決 世話 危険 通知 連絡 計画 現場 企業 輸出 教育 支持 変化 交換 包帯 迅速 観察 血液 感覚 独立 関係 成績 記録 感動 動作 悩み 空気 責任 手続き 迷惑 予約 疑問 保証 項目 損失 秘書 圧力 交渉 調査 事業 現実 期限 回答 発足 密集 瞬間 執念 品種 腹筋 躊躇う 呆れる 発送 費やす 落胆 断念 発見 進展 徹夜 伝説 尊い 飼料 回転 火花 呼吸 全身 台詞 安価 主役 溢れる 洋服 熟知 原著 倒産 脚本 手渡す 出前 我慢 誘い 刻む 嘆息 頷く 公寓 生まれる 必然 激動 穏やか 即刻 布団 忠誠 保護 作物 周辺 孤児 稼ぐ 玄関 下駄箱 散歩 場所 墓碑 専門 程度 隙間 無数 可能性 帰国 告白 非難 資源 出資 提供 投資 名刺 脱出 完全 食料品 幸福 天気 舗装道路 気温 触感 距離 交替 確認 人事 裏側 居住者 懲罰 微笑み 蓋 カーテン ストレス キャンパス ドラマ コメント コンビニ エアコン キーボード ハンドル ラーメン アルバイト ヘルメット キャッシュカード マンション プロジェクト コーヒー メッセージ'.split()
# Meanings below are copied from the source tables, explicitly identified as source annotations.
short=[
[('振り返る','回顾，反省'),('振り切る','拒绝，摆脱，甩开'),('振り回す','挥舞，滥用，摆弄'),('振り替える','转账，调换'),('振り込む','汇款，存入')],
[('気を付ける','小心，注意'),('気に入る','喜欢'),('気になる','在意，关心'),('気にする','在意，担心'),('気がつく','意识到，注意到')],
[('打ち込む','热衷，拼命工作'),('打ち出す','提出，打出，制定'),('打ち消す','否定，取消'),('打ち明ける','坦白，倾诉'),('打ち合わせる','商量'),('打ち解ける','敞开心扉，融洽')],
[('詰め込む','填鸭式学习，塞满，灌输'),('入れ込む','着迷，振奋，装入'),('落ち込む','心情低落，陷入困境'),('思い込む','深信不疑，误以为'),('割り込む','打断，插话，插入，插队')],
[('引き取る','退出，领取，收养，死亡'),('引っ掛ける','撞上，挂上，欺骗，泼洒，小口喝'),('引き起こす','引起，扶起'),('引き受ける','继承，接受，承担'),('引き止める','阻止，挽留'),('引き出す','提出，提取，引出')],
[('差し控える','避免，克制，暂缓'),('差し掛かる','来到，接近，遮盖'),('差し支える','有碍，妨碍，影响'),('差し出す','递出，伸出'),('差し上げる','赠送'),('差し替える','调换')],
[('思い合う','相互思念'),('思い返す','反省，回顾'),('思い当たる','意识到，想到'),('思い立つ','想要做，下决心'),('思い詰める','过度思虑，钻牛角尖'),('思い浮かべる','浮现于脑海')],
[('受け持つ','担任，负责'),('受け取る','接受，理解，承担'),('受け合う','承诺'),('受け入れる','接纳'),('受け止める','阻止，接住，理解'),('受け継ぐ','继承')],
[('取り組む','致力于，处理，投入'),('取り次ぐ','转达，传递，代办，经销'),('取り出す','拿出，挑出'),('取り消す','取消'),('取り上げる','举起，采纳，没收，报道')],
[('打ち込む','热衷，拼命工作，输入，融入'),('打ち切る','中断'),('打ち合わせる','商量'),('打ち消す','否认，取消'),('打ち明ける','坦白，倾诉')],
[('こつこつ','孜孜不倦'),('つるつる','光滑'),('じろじろ','目不转睛'),('わくわく','兴奋'),('もじもじ','扭捏')],
[('いやに','异常，非常，讨厌地'),('きっぱり','果断'),('いまだ','尚未'),('きっかり','清晰，正好'),('べったり','过分依赖，黏糊糊'),('じっくり','慢慢地，仔细'),('ぐっすり','熟睡'),('ゆっくり','慢慢地')],
[('しっとり','潮湿，沉静'),('じっくり','仔细'),('ざあざあ','哗啦哗啦'),('ぴったり','严丝合缝'),('ぐったり','筋疲力尽'),('しとしと','淅淅沥沥'),('こっそり','悄悄，偷偷')],
[('どきっと','震惊'),('すっと','一下子，一直'),('ほっと','安心，松口气'),('ざっと','粗略地，大致'),('ひょっと','忽然，或许'),('そっと','悄悄，偷偷')],
[('もっぱら','独揽，专门'),('しきりに','频繁地'),('すっきり','痛快，清爽'),('なんら','毫无'),('ぐらぐら','不稳定'),('ありあり','明显，显而易见'),('のろのろ','缓慢'),('どんより','阴沉')],
[('ふと','突然'),('ひしひし','感觉强烈，切实'),('ふんわり','蓬松'),('うっとり','陶醉'),('がらりと','突然，彻底'),('あっさり','口味清淡，简单，朴素'),('ぎくしゃく','不自然，生硬'),('かねがね','很久以前')]]
lessons=[];questions=[];explanations=[];papers=[]
with pdfplumber.open(pdf) as doc:
 for idx,(start,title) in enumerate(zip(starts,titles)):
  end=starts[idx+1]-1 if idx+1<len(starts) else 297; lid=f'novel-lesson-{idx+1:02}';pid=lid+'-practice';category='长篇小说' if idx<12 else '复合动词' if idx<22 else '副词';pages=[];recall=False
  for number in range(start,end+1):
   p=doc.pages[number-1];text=p.filter(lambda o:o.get('object_type')!='char' or o.get('size',0)<25).extract_text() or ''
   text=re.sub(r'第\s*\d+\s*页\s*共\s*298\s*页','',text).strip()
   if text.startswith('背诵回忆版'):recall=True
   page=dict(number=number,text=text,recall=recall)
   if idx>=12:
    target=assets/f'novel-page-{number}.jpg';p.to_image(resolution=125).original.convert('RGB').save(target,quality=85)
    page['imageUrl']='http://127.0.0.1:3002/study-assets/'+target.name
   pages.append(page)
  entries=[]
  if idx<12:
   for page in pages:
    if page['recall']:continue
    compact=''.join(page['text'].split())
    for word in words:
     if any(v['word']==word for v in entries):continue
     match=re.search(re.escape(word)+r'(?=[ぁ-ゖァ-ヺー])',compact) if re.search(r'[一-龥]',word) else re.search(re.escape(word),compact)
     if not match:continue
     pos=match.start();left=max(compact.rfind('。',0,pos),compact.rfind('：',0,pos),compact.rfind('！',0,pos))+1;right=compact.find('。',pos)
     if right<0:right=min(len(compact),pos+60)
     excerpt=compact[max(left,pos-55):min(right+1,pos+90)]
     if any(x in excerpt for x in ['浴巾','裤衩','内裤','脱衣','亲吻','体内','裤腰','鸡爸','包养','金丝雀','八块','小鸡','大鸡','无毛鸡']):continue
     entries.append(dict(word=word,sourcePage=page['number'],excerpt=excerpt,kind='source_recall'))
     if len(entries)==10:break
    if len(entries)==10:break
  else:
   for word,meaning in short[idx-12]:
    found=None
    for page in pages:
     compact=''.join(page['text'].split());normalized=compact.replace('，','').replace('、','')
     if word in compact and re.search('.*?'.join(re.escape(c) for c in meaning if c not in '，、'), compact[compact.index(word):compact.index(word)+180]):
      # Exact supporting quote spans the source word and its copied annotation.
      pos=compact.index(word);following=[compact.find(w,pos+len(word)) for w,_ in short[idx-12] if w!=word];stop=min([n for n in following if n>=0]+[len(compact)])
      excerpt=compact[pos:stop];found=dict(word=word,meaning=meaning,sourcePage=page['number'],excerpt=excerpt,kind='source_annotation');break
    if found:entries.append(found)
  assert len(entries)>=4,(idx,title,len(entries))
  qids=[]
  for j,entry in enumerate(entries,1):
   word=entry['word'];qid=f'{lid}-q{j:02}';eid=qid+'-explanation';pool=[e['word'] for e in entries if e['word']!=word];rng=random.Random(qid);opts=[word]+rng.sample(pool,3);rng.shuffle(opts)
   options=[dict(id=qid+f'-o{k+1}',content=v,index=k) for k,v in enumerate(opts)];answer=next(o['id'] for o in options if o['content']==word)
   excerpt=entry['excerpt'];prompt=('原文记忆：还原下面片段中的词语。\n'+excerpt.replace(word,'（　）')) if idx<12 else '按原材料词表，注释“'+entry['meaning']+'”对应哪个词？'
   reason='本题按原材料作答，应选「'+word+'」。\n原文依据：「'+excerpt+'」。'
   if idx>=12:reason+='\n词表原注释：'+entry['meaning']+'。这些是材料注释，未经独立词典或等级核验。'
   else:reason+='\n本题训练原文记忆，不将混合语言故事的注释用法作为规范日语例句。'
   questions.append(dict(id=qid,level='ungraded',type='vocabulary',content=prompt,options=options,answer=answer,source='custom',explanationId=eid,tags=['小说词汇','素材改编',category],order=j,provenance=dict(kind='user_material',collection='novel',lessonId=lid,materialId=mid,title=title,filename=pdf.name,pdfPage=entry['sourcePage'],pdfSha256=digest,sourceUrl=f'http://127.0.0.1:3002/study-assets/{mid}.pdf',passage=excerpt,supportingQuote=excerpt,authoring='依据用户原材料制作的原文记忆/注释对应练习，非JLPT真题',levelStatus='source_title_only_not_jlpt_certified')))
   explanations.append(dict(id=eid,questionId=qid,translation='',sentenceStructure=reason,wordAnalysis=[],grammar=[],optionAnalysis=[dict(optionId=o['id'],isCorrect=o['id']==answer,reason='与原材料对应。' if o['id']==answer else '不是本处原材料对应的词语。') for o in options],extensions=[],note=f'出处：{pdf.name} 第{entry["sourcePage"]}页。原作者：@叫我とうさん。'))
   qids.append(qid)
  lessons.append(dict(id=lid,materialId=mid,paperId=pid,title=title,category=category,position=idx+1,startPage=start,endPage=end,pages=pages,vocabulary=entries,note='素材标题中的N1为原作者标注，不代表本平台已验证JLPT等级。练习按原文记忆或材料注释作答，混合语言故事不是规范日语例句。'))
  papers.append(dict(id=pid,title='小说词汇 · '+title,description='先读原文，再做词汇记忆练习；错题讲解后手动继续。',theme='小说词汇',questionIds=qids,materialIds=[mid],published=True))
(backend/'data/novel-lessons.json').write_text(json.dumps(dict(lessons=lessons,papers=papers,questions=questions,explanations=explanations),ensure_ascii=False,indent=2))
print(json.dumps(dict(lessons=len(lessons),questions=len(questions),pages=sum(len(x['pages']) for x in lessons),perLesson=[len(x['vocabulary']) for x in lessons])))
