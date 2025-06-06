from app import app, db, Game
import requests
import time
from datetime import datetime
import os
import json
import stat
import subprocess
import csv
from sqlalchemy import inspect

STEAM_APP_LIST_URL = 'https://api.steampowered.com/ISteamApps/GetAppList/v2/'
BATCH_SIZE = 5

# 获取当前文件夹绝对路径
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
INSTANCE_DIR = os.path.join(BASE_DIR, 'instance')
PROGRESS_FILE = os.path.join(BASE_DIR, 'progress_sync_steam_games.txt')
db_path = os.path.join(INSTANCE_DIR, 'gamestock.db')
CSV_FILE = os.path.join(BASE_DIR, 'steam_games_backup.csv')
JSONL_FILE = os.path.join(BASE_DIR, 'steam_games_backup.jsonl')
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'

# 路径和权限检查
print(f"[路径检查] BASE_DIR: {BASE_DIR}")
print(f"[路径检查] INSTANCE_DIR: {INSTANCE_DIR}")
print(f"[路径检查] DB_PATH: {db_path}")

# 检查父目录权限
parent_dir = os.path.dirname(BASE_DIR)
parent_mode = oct(os.stat(parent_dir).st_mode)[-3:]
print(f"[路径检查] 父目录: {parent_dir} 权限: {parent_mode}")
if parent_mode not in ("777", "775", "755"):
    print(f"[警告] 父目录权限为 {parent_mode}，建议为 777/775/755。尝试自动修正...")
    try:
        os.chmod(parent_dir, 0o755)
        print(f"[自动修复] 父目录权限已设为755。")
    except Exception as e:
        print(f"[错误] 父目录权限修正失败: {e}")

# 检查并修复instance目录
if not os.path.exists(INSTANCE_DIR):
    print(f"[自动修复] instance 目录不存在，正在创建...")
    try:
        os.makedirs(INSTANCE_DIR, exist_ok=True)
        print(f"[自动修复] 已创建 instance 目录。")
    except Exception as e:
        print(f"[错误] 创建 instance 目录失败: {e}")
        exit(1)
try:
    os.chmod(INSTANCE_DIR, 0o777)
    print(f"[自动修复] instance 目录权限已设为777。")
except Exception as e:
    print(f"[错误] instance 目录权限修正失败: {e}")
try:
    subprocess.run(['xattr', '-c', INSTANCE_DIR], check=False)
    print(f"[自动修复] 已清理 instance 目录扩展属性。")
except Exception as e:
    print(f"[警告] 清理 instance 目录扩展属性失败: {e}")

# 检查数据库文件
if os.path.exists(db_path):
    print(f"[检查] 数据库文件已存在: {db_path}")
    try:
        os.chmod(db_path, 0o666)
        print(f"[自动修复] 数据库文件权限已设为666。")
    except Exception as e:
        print(f"[错误] 数据库文件权限修正失败: {e}")
    try:
        subprocess.run(['xattr', '-c', db_path], check=False)
        print(f"[自动修复] 已清理数据库文件扩展属性。")
    except Exception as e:
        print(f"[警告] 清理数据库文件扩展属性失败: {e}")
else:
    print(f"[提示] 数据库文件不存在，将在首次写入时自动创建。")

def print_resource_status(batch_idx):
    try:
        ulimit = subprocess.getoutput('ulimit -n')
        print(f"[资源监控] 当前ulimit -n: {ulimit}")
        df = subprocess.getoutput(f'df -h "{BASE_DIR}"')
        print(f"[资源监控] 磁盘空间: \n{df}")
        if os.path.exists(db_path):
            out = subprocess.getoutput(f'sqlite3 "{db_path}" "PRAGMA integrity_check;"')
            print(f"[资源监控] 数据库完整性: {out}")
    except Exception as e:
        print(f"[资源监控错误] {e}")

def fetch_steam_applist(max_retries=5):
    for attempt in range(max_retries):
        try:
            print(f"尝试拉取Steam全量游戏列表（第{attempt+1}次）...")
            resp = requests.get(
                STEAM_APP_LIST_URL,
                timeout=300,
                stream=True
            )
            resp.raise_for_status()
            data = resp.content
            try:
                apps = json.loads(data)['applist']['apps']
            except Exception:
                apps = json.loads(data.decode('utf-8'))['applist']['apps']
            print(f"拉取成功，共{len(apps)}个游戏。")
            return apps
        except Exception as e:
            print(f"拉取失败: {e}")
            time.sleep(3)
    print("多次尝试后仍然失败，请检查网络环境。")
    return []

def load_progress():
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, 'r') as f:
            try:
                return int(f.read().strip())
            except Exception as e:
                print(f"[进度文件读取错误] {e}")
                return 0
    return 0

def save_progress(batch_idx):
    try:
        with open(PROGRESS_FILE, 'w') as f:
            f.write(str(batch_idx))
    except Exception as e:
        print(f"[进度文件保存错误] {e}")

def sync_games():
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

    # 初始化CSV和JSONL文件（首批写入表头/清空）
    if start_batch == 0:
        with open(CSV_FILE, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['appid', 'name'])
        with open(JSONL_FILE, 'w', encoding='utf-8') as jsonlfile:
            pass  # 清空内容

    for batch_idx in range(start_batch, total_batches):
        batch = applist[batch_idx*BATCH_SIZE : (batch_idx+1)*BATCH_SIZE]
        # 追加写入CSV和JSONL
        try:
            with open(CSV_FILE, 'a', newline='', encoding='utf-8') as csvfile, \
                 open(JSONL_FILE, 'a', encoding='utf-8') as jsonlfile:
                csv_writer = csv.writer(csvfile)
                for app in batch:
                    appid = app.get('appid')
                    name = app.get('name')
                    if not appid or not name:
                        continue
                    # 数据库写入
                    try:
                        game = Game.query.filter_by(appid=appid).first()
                        if game:
                            game.name = name
                            game.last_update = datetime.utcnow()
                        else:
                            game = Game(appid=appid, name=name, last_update=datetime.utcnow())
                            db.session.add(game)
                    except Exception as e:
                        print(f"[数据库写入错误] appid={appid} name={name} 错误: {e}")
                    # CSV写入
                    try:
                        csv_writer.writerow([appid, name])
                    except Exception as e:
                        print(f"[CSV写入错误] appid={appid} name={name} 错误: {e}")
                    # JSONL写入
                    try:
                        jsonlfile.write(json.dumps({'appid': appid, 'name': name}, ensure_ascii=False) + '\n')
                    except Exception as e:
                        print(f"[JSONL写入错误] appid={appid} name={name} 错误: {e}")
        except Exception as e:
            print(f"[文件写入错误] 批次 {batch_idx+1}: {e}")
        # 数据库提交与session关闭
        try:
            db.session.commit()
        except Exception as e:
            print(f"[数据库提交错误] 批次 {batch_idx+1}: {e}")
        try:
            db.session.close()
            if inspect(db.engine).pool.checkedout():
                print("[警告] 数据库连接未完全释放")
        except Exception as e:
            print(f"[session关闭错误] {e}")
        save_progress(batch_idx+1)
        print(f"已完成第 {batch_idx+1}/{total_batches} 批（共{BATCH_SIZE}个），进度已保存。")
        if (batch_idx+1) % 1000 == 0:
            print_resource_status(batch_idx+1)
    print(f"全部完成！共处理 {total} 个游戏。耗时 {time.time() - start_time:.1f} 秒。")
    if os.path.exists(PROGRESS_FILE):
        os.remove(PROGRESS_FILE)

def main():
    with app.app_context():
        sync_games()

if __name__ == "__main__":
    main() 