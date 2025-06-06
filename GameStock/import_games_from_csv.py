import csv
import os
from app import app, db, Game

CSV_FILE = os.path.join(os.path.dirname(__file__), 'steam_games_backup.csv')
PROGRESS_FILE = os.path.join(os.path.dirname(__file__), 'import_games_progress.txt')
BATCH_SIZE = 1000

def load_progress():
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, 'r') as f:
            try:
                return int(f.read().strip())
            except Exception:
                return 0
    return 0

def save_progress(row_idx):
    with open(PROGRESS_FILE, 'w') as f:
        f.write(str(row_idx))

def import_csv_to_db():
    with app.app_context():
        print(f"开始从 {CSV_FILE} 导入数据到数据库...")
        start_row = load_progress()
        print(f"当前进度：已完成 {start_row} 行，将从第 {start_row+1} 行开始。")
        with open(CSV_FILE, newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            batch = []
            for idx, row in enumerate(reader):
                if idx < start_row:
                    continue
                appid = int(row['appid'])
                name = row['name']
                game = Game.query.filter_by(appid=appid).first()
                if not game:
                    game = Game(appid=appid, name=name)
                    db.session.add(game)
                else:
                    game.name = name
                batch.append(game)
                if len(batch) >= BATCH_SIZE:
                    db.session.commit()
                    save_progress(idx+1)
                    print(f"已导入 {idx+1} 行...")
                    batch = []
            if batch:
                db.session.commit()
                save_progress(idx+1)
                print(f"已导入 {idx+1} 行...")
        print("全部导入完成！")
        if os.path.exists(PROGRESS_FILE):
            os.remove(PROGRESS_FILE)

if __name__ == '__main__':
    import_csv_to_db() 