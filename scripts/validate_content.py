"""Validate Phase 0 source coverage and the reviewed playable-schema example."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
content = ROOT / "assets/content"
manifest = json.loads((content / "manifest.json").read_text(encoding="utf-8-sig"))
digest = hashlib.sha256((ROOT / manifest["sourceFile"]).read_bytes()).hexdigest()
assert digest == manifest["sourceSha256"]
seen = set()
question_count = 0
for kind, count, expected in [("unit", 9, 13), ("quiz", 4, 10)]:
    for n in range(1, count + 1):
        data = json.loads((content / f"{kind}_{n:02d}.json").read_text(encoding="utf-8-sig"))
        assert data["sourceSha256"] == digest
        assert data["status"] == "source_draft"
        assert data["playableQuestions"] == []
        records = data["sourceQuestions"]
        assert len(records) == expected, data["id"]
        for record in records:
            assert record["id"] not in seen
            seen.add(record["id"])
            for key in ("sourceText", "answerKeyText"):
                assert record[key].strip(), record["id"]
            for key in ("sourcePages", "answerKeyPages"):
                assert record[key] and all(1 <= p <= 39 for p in record[key])
            assert record["reviewStatus"] == "extracted_needs_game_adaptation"
        if kind == "quiz":
            assert [r["number"] for r in records] == list(range(1, 11))
            covered = [v for band in data["scoreBands"] for v in range(band["min"], band["max"] + 1)]
            assert sorted(covered) == list(range(11))
        else:
            assert [r["number"] for r in records[:8]] == list(range(1, 9))
            assert [r["number"] for r in records[8:]] == list(range(1, 6))
        question_count += len(records)
assert question_count == 157
for path in content.glob("*.json"):
    text = path.read_text(encoding="utf-8-sig")
    json.loads(text)
    assert "Seif Hossam Nader" not in text, "Remove identifying PDF footer"
print("PASS: 157 source questions; 9 units; 4 quizzes; source hash, references, IDs and score bands.")

sample = json.loads((ROOT / "docs/examples/unit_01_choice_01.json").read_text(encoding="utf-8-sig"))
options = {o["id"]: o["text"]["en"] for o in sample["options"]}
assert len(options) == len(sample["options"])
assert sample["answer"]["kind"] == "single"
assert sample["answer"]["optionId"] in options
unit = json.loads((content / "unit_01.json").read_text(encoding="utf-8-sig"))
source = next(r for r in unit["sourceQuestions"] if r["id"] == sample["source"]["questionId"])
assert options[sample["answer"]["optionId"]] == source["answerKeyText"]
assert sample["source"]["sourceSha256"] == digest
print("PASS: scene-task example has exactly one valid answer matching the Answer Key.")
try:
    import jsonschema
except ImportError:
    print("NOTE: JSON Schema library unavailable; schema validation not run.")
else:
    schema = json.loads((ROOT / "schemas/question.schema.json").read_text(encoding="utf-8-sig"))
    jsonschema.Draft202012Validator.check_schema(schema)
    jsonschema.validate(sample, schema)
    print("PASS: proposed JSON Schema and example.")
