export const timingSource = 'https://www.jlpt.jp/e/guideline/testsections.html';
export function examSections(level: string, year?: number | null, month?: number | null) {
  const before2020 = year != null && (year < 2020 || (year === 2020 && (month ?? 12) < 12));
  const before2022 = year != null && (year < 2022 || (year === 2022 && (month ?? 12) < 12));
  const combined = [{ id:'knowledge_reading', title:'语言知识（文字、词汇、语法）・阅读', minutes:level==='n1'?110:105 }, {id:'listening',title:'听力',minutes:level==='n1'?(before2022?60:55):50}];
  const lower: Record<string,number[]> = {n3:[30,70,40],n4:before2020?[30,60,35]:[25,55,35],n5:before2020?[25,50,30]:[20,40,30]};
  if(level==='n1'||level==='n2')return combined;
  return ['vocabulary','grammar_reading','listening'].map((id,i)=>({id,title:['语言知识（文字、词汇）','语言知识（语法）・阅读','听力'][i],minutes:lower[level][i]}));
}
export function examConfig(paper: any, instantFeedback: boolean) {
  const sections = paper.sections as any[];
  const first=sections[0];const now=Date.now();
  return {paperId:paper.id,paperTitle:paper.title,instantFeedback,sections,sectionIndex:0,waitingSection:false,
    sectionStartedAt:new Date(now).toISOString(),deadline:new Date(now+first.minutes*60000).toISOString(),timingSource,
    timingProfile:paper.kind==='dated_exam'?'原考试日期对应规则':'现行规则（官方问题集无具体考试日期）'};
}
