"""Read the historical SQLite export without copying it into the project."""
import json
import sqlite3
import sys

connection = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
connection.row_factory = sqlite3.Row

def rows(query, parameters=()):
    return [dict(row) for row in connection.execute(query, parameters)]

papers = rows("SELECT * FROM FunPaper WHERE id LIKE 'material-adventure-%' ORDER BY id")
question_ids = [question_id for paper in papers for question_id in json.loads(paper["questionIds"])]
placeholders = ",".join("?" for _ in question_ids)
questions = rows(f"SELECT * FROM Question WHERE id IN ({placeholders})", question_ids)
explanations = rows(f"SELECT * FROM Explanation WHERE questionId IN ({placeholders})", question_ids)
materials = rows("SELECT id, title, japanese, translation FROM StudyMaterial WHERE id LIKE 'short-%' ORDER BY id")
print(json.dumps({"materials": materials, "papers": papers, "questions": questions, "explanations": explanations}, ensure_ascii=False))
