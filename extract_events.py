import sqlite3
import json

db_path = "/tmp/The-believer-s-bag/حقيبة المؤمن/assets/database.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("SELECT m, d, event FROM calendar_events")
rows = cursor.fetchall()

events = []
for row in rows:
    events.append({
        "month": row[0],
        "day": row[1],
        "title": row[2]
    })

print(f"Extracted {len(events)} events.")
with open("extracted_events.json", "w", encoding="utf-8") as f:
    json.dump(events, f, ensure_ascii=False, indent=2)

conn.close()
