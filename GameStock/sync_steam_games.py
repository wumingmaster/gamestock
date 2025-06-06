from app import app, db, Game
import requests
import time
from datetime import datetime

STEAM_APP_LIST_URL = 'https://api.steampowered.com/ISteamApps/GetAppList/v2/'

BATCH_SIZE = 1000

def fetch_steam_applist():
    try:
        resp = requests.get(STEAM_APP_LIST_URL, timeout=120)
        resp.raise_for_status()
        data = resp.json()
        return data['applist']['apps']
    except Exception as e:
        print(f"拉取Steam全量游戏列表失败: {e}")
        return []

def sync_games():
    print("开始拉取Steam全量游戏列表...")
    start_time = time.time()
    applist = fetch_steam_applist()
    if not applist:
        print("未获取到任何游戏数据，请检查网络或稍后重试。")
        return
    total = len(applist)
    print(f"共获取到 {total} 个游戏，开始写入数据库...")

    count = 0
    for i, app in enumerate(applist):
        appid = app.get('appid')
        name = app.get('name')
        if not appid or not name:
            continue
        # upsert
        game = Game.query.filter_by(appid=appid).first()
        if game:
            game.name = name
            game.last_update = datetime.utcnow()
        else:
            game = Game(appid=appid, name=name, last_update=datetime.utcnow())
            db.session.add(game)
        count += 1
        if count % BATCH_SIZE == 0:
            db.session.commit()
            print(f"已处理 {count}/{total} 个游戏...")
    db.session.commit()
    print(f"全部完成！共处理 {count} 个游戏。耗时 {time.time() - start_time:.1f} 秒。")


def main():
    with app.app_context():
        sync_games()

if __name__ == "__main__":
    main() 