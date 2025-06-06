import csv
import json
from datetime import datetime
from Models.models import db, Game

def sync_steam_games():
    # ... existing code ...
    with open('steam_games.csv', 'w', newline='') as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(['steam_id', 'name'])

    with open('steam_games.jsonl', 'w') as jsonlfile:
        # ... existing code ...
        for app in apps:
            steam_id = app.get('appid')
            if not steam_id or not name:
                continue
            game = Game.query.filter_by(steam_id=steam_id).first()
            if not game:
                game = Game(steam_id=steam_id, name=name, last_update=datetime.utcnow())
            # ... existing code ...
            try:
                csv_writer.writerow([steam_id, name])
                jsonlfile.write(json.dumps({'steam_id': steam_id, 'name': name}, ensure_ascii=False) + '\n')
            except Exception as e:
                print(f"[数据库写入错误] steam_id={steam_id} name={name} 错误: {e}")
            # ... existing code ...
            try:
                csv_writer.writerow([steam_id, name])
            except Exception as e:
                print(f"[CSV写入错误] steam_id={steam_id} name={name} 错误: {e}")
            # ... existing code ...
            try:
                jsonlfile.write(json.dumps({'steam_id': steam_id, 'name': name}, ensure_ascii=False) + '\n')
            except Exception as e:
                print(f"[JSONL写入错误] steam_id={steam_id} name={name} 错误: {e}")
            # ... existing code ...
    # ... existing code ... 