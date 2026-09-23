"""Reproduce source records from the parent's PDF; never infer answers."""
import hashlib
import json
import re
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
PDF = ROOT / "curriculum/Science_Made_Simple.pdf"
OUT = ROOT / "assets/content"
OUT.mkdir(parents=True, exist_ok=True)
reader = PdfReader(PDF)
digest = hashlib.sha256(PDF.read_bytes()).hexdigest()


def clean(text):
    lines = []
    for line in text.splitlines():
        if "Science Made Simple" in line and "Page " in line:
            continue
        if line.strip():
            lines.append(re.sub(r"[\t ]+", " ", line).strip())
    return "\n".join(lines)


pages = {i + 1: clean(p.extract_text(extraction_mode="layout"))
         for i, p in enumerate(reader.pages)}


def section(start, end):
    return "\n".join(pages[i] for i in range(start, end + 1))


def numbered(text):
    matches = list(re.finditer(r"(?m)^(\d+)\.\s+", text))
    return [{"number": int(m[1]), "text": text[m.end():
             matches[i + 1].start() if i + 1 < len(matches) else len(text)].strip()}
            for i, m in enumerate(matches)]


def write(name, data):
    (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


units = [
    ("Alive or Not Alive?", 4, 5, [35], "biology"),
    ("Plants", 6, 7, [35], "biology"),
    ("Ourselves", 8, 10, [35], "biology"),
    ("Material Properties", 12, 13, [35, 36], "materials"),
    ("Forces", 15, 16, [36], "physics"),
    ("Sound", 17, 18, [36], "physics"),
    ("Electricity and Magnets", 19, 20, [36], "physics"),
    ("Planet Earth", 22, 23, [36, 37], "earth_space"),
    ("Earth in Space", 24, 25, [37], "earth_space"),
]
answers = section(35, 38)
inventory = []
for n, (title, start, end, key_pages, island) in enumerate(units, 1):
    body = section(start, end)
    introduction, questions = body.split(f"Questions — Unit {n}", 1)
    main, choices = questions.split(f"Choose the correct answer — Unit {n}", 1)
    key = re.split(rf"(?m)^Unit {n} — [^\n]+\n", answers)[1]
    key = re.split(r"(?m)^(?:Unit \d+ — |Chart Skills)", key)[0]
    main_key, choice_key = key.split("Choose the correct answer:", 1)
    questions_main, key_main = numbered(main), numbered(main_key)
    choice_answers = dict((int(m[1]), m[2].strip()) for m in
                          re.finditer(r"(\d+) ([^•]+)", choice_key))
    choices_main = numbered(choices)
    assert len(questions_main) == len(key_main) == 8
    assert len(choices_main) == len(choice_answers) == 5
    records = []
    for category, items in [("main", questions_main), ("choice", choices_main)]:
        for item in items:
            num = item["number"]
            records.append({
                "id": f"u{n:02d}.{category}.{num:02d}",
                "category": category,
                "number": num,
                "sourceText": item["text"],
                "answerKeyText": key_main[num - 1]["text"] if category == "main" else choice_answers[num],
                "sourcePages": list(range(start, end + 1)),
                "answerKeyPages": key_pages,
                "reviewStatus": "extracted_needs_game_adaptation",
            })
    write(f"unit_{n:02d}.json", {
        "schemaVersion": "0.1.0", "contentVersion": 1,
        "id": f"unit_{n:02d}", "kind": "unit", "title": title,
        "island": island, "sourceSha256": digest,
        "sourcePages": list(range(start, end + 1)),
        "introductionText": introduction, "sourceQuestions": records,
        "activities": [], "playableQuestions": [], "status": "source_draft",
    })
    inventory.append({"id": f"unit_{n:02d}", "pages": list(range(start, end + 1)),
                      "mainQuestions": 8, "choiceQuestions": 5, "answerKeyPages": key_pages})

for n, (title, page, key_pages) in enumerate([
    ("Biology", 11, [37]), ("Chemistry", 14, [37, 38]),
    ("Physics", 21, [38]), ("Earth and Space", 26, [38]),
], 1):
    questions = numbered(pages[page].split("My score:", 1)[0])
    key = re.split(rf"(?m)^Quiz {n} — [^\n]+\n", answers)[1]
    key = re.split(r"(?m)^Quiz \d+ — ", key)[0]
    key_items = numbered(key)
    assert len(questions) == len(key_items) == 10
    records = [{"id": f"quiz{n:02d}.{q['number']:02d}", "number": q["number"],
                "sourceText": q["text"], "answerKeyText": key_items[i]["text"],
                "sourcePages": [page], "answerKeyPages": key_pages,
                "reviewStatus": "extracted_needs_game_adaptation"}
               for i, q in enumerate(questions)]
    write(f"quiz_{n:02d}.json", {
        "schemaVersion": "0.1.0", "contentVersion": 1, "id": f"quiz_{n:02d}",
        "kind": "quiz", "title": title + " Quiz", "sourceSha256": digest,
        "sourcePages": [page], "sourceQuestions": records,
        "playableQuestions": [], "status": "source_draft",
        "scoreBands": [{"min": 8, "max": 10}, {"min": 5, "max": 7}, {"min": 0, "max": 4}],
    })

for name, start, end in [("parent_guide", 2, 2), ("charts", 27, 28),
                          ("record_sheets", 29, 30), ("sorting_cards", 31, 31),
                          ("self_check", 32, 32), ("word_list", 33, 34), ("certificate", 39, 39)]:
    write(name + ".json", {"schemaVersion": "0.1.0", "contentVersion": 1,
                          "id": name, "kind": "reference", "status": "source_draft",
                          "sourceSha256": digest, "sourcePages": list(range(start, end + 1)),
                          "sourceText": section(start, end)})

write("manifest.json", {"schemaVersion": "0.1.0", "sourceFile": "curriculum/Science_Made_Simple.pdf",
                        "sourceSha256": digest, "pageCount": len(reader.pages),
                        "units": inventory, "quizCount": 4, "quizQuestionCount": 40,
                        "unitQuestionCount": 117, "chartQuestionCount": 10,
                        "selfCheckCount": 20, "status": "source_draft"})
print("Extracted 9 units (117 questions), 4 quizzes (40 questions), and 7 reference files.")
