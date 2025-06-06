from app import app, db, Game
import requests
import time
from datetime import datetime
import os

STEAM_APP_LIST_URL = 'https://api.steampowered.com/ISteamApps/GetAppList/v2/'
BATCH_SIZE = 50

# 获取项目根目录的绝对路径
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROGRESS_FILE = os.path.join(BASE_DIR, 'progress_sync_steam_games.txt')

# 强制设置SQLAlchemy数据库绝对路径（防止app.py配置不一致）
db_path = os.path.join(BASE_DIR, 'instance', 'gamestock.db')
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'

def fetch_steam_applist():
    try:
        resp = requests.get(STEAM_APP_LIST_URL, timeout=120)
        resp.raise_for_status()
        data = resp.json()
        return data['applist']['apps']
    except Exception as e:
        print(f"拉取Steam全量游戏列表失败: {e}")
        return []

def load_progress():
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, 'r') as f:
            try:
                return int(f.read().strip())
            except Exception:
                return 0
    return 0

def save_progress(batch_idx):
    with open(PROGRESS_FILE, 'w') as f:
        f.write(str(batch_idx))

def sync_games():
    print("开始拉取Steam全量游戏列表...")
    start_time = time.time()
    applist = fetch_steam_applist()
    if not applist:
        print("未获取到任何游戏数据，请检查网络或稍后重试。")
        return
    total = len(applist)
    print(f"共获取到 {total} 个游戏，按每批{BATCH_SIZE}个分批处理...")

    # 断点续传
    start_batch = load_progress()
    total_batches = (total + BATCH_SIZE - 1) // BATCH_SIZE
    print(f"当前进度：已完成 {start_batch}/{total_batches} 批。将从第 {start_batch+1} 批开始。")

    for batch_idx in range(start_batch, total_batches):
        batch = applist[batch_idx*BATCH_SIZE : (batch_idx+1)*BATCH_SIZE]
        for app in batch:
            appid = app.get('appid')
            name = app.get('name')
            if not appid or not name:
                continue
            game = Game.query.filter_by(appid=appid).first()
            if game:
                game.name = name
                game.last_update = datetime.utcnow()
            else:
                game = Game(appid=appid, name=name, last_update=datetime.utcnow())
                db.session.add(game)
        db.session.commit()
        save_progress(batch_idx+1)
        print(f"已完成第 {batch_idx+1}/{total_batches} 批（共{BATCH_SIZE}个），进度已保存。")
    print(f"全部完成！共处理 {total} 个游戏。耗时 {time.time() - start_time:.1f} 秒。")
    # 同步完成后清理进度文件
    if os.path.exists(PROGRESS_FILE):
        os.remove(PROGRESS_FILE)

def main():
    with app.app_context():
        sync_games()

if __name__ == "__main__":
    main() 