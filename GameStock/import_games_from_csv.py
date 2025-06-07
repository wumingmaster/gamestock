import csv
import os
import stat
import subprocess
from models import db, Game

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////root/GameStock/instance/gamestock.db'
db.init_app(app)

# 强制绝对路径
CSV_FILE = '/root/GameStock/GameStock/steam_games_backup.csv'
PROGRESS_FILE = '/root/GameStock/GameStock/import_games_progress.txt'
INSTANCE_DIR = '/root/GameStock/instance'
DB_FILE = '/root/GameStock/instance/gamestock.db'
BATCH_SIZE = 1000

# 路径和权限检查
print(f"[路径检查] CSV_FILE: {CSV_FILE}")
print(f"[路径检查] INSTANCE_DIR: {INSTANCE_DIR}")
print(f"[路径检查] DB_FILE: {DB_FILE}")

# 检查父目录权限
parent_dir = '/root/GameStock'
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
if os.path.exists(DB_FILE):
    print(f"[检查] 数据库文件已存在: {DB_FILE}")
    try:
        os.chmod(DB_FILE, 0o666)
        print(f"[自动修复] 数据库文件权限已设为666。")
    except Exception as e:
        print(f"[错误] 数据库文件权限修正失败: {e}")
    try:
        subprocess.run(['xattr', '-c', DB_FILE], check=False)
        print(f"[自动修复] 已清理数据库文件扩展属性。")
    except Exception as e:
        print(f"[警告] 清理数据库文件扩展属性失败: {e}")
else:
    print(f"[错误] 数据库文件不存在: {DB_FILE}，请先用Flask初始化数据库！")

# 检查CSV文件
if os.path.exists(CSV_FILE):
    print(f"[检查] CSV文件已存在: {CSV_FILE}")
    try:
        os.chmod(CSV_FILE, 0o666)
        print(f"[自动修复] CSV文件权限已设为666。")
    except Exception as e:
        print(f"[错误] CSV文件权限修正失败: {e}")
else:
    print(f"[错误] CSV文件不存在: {CSV_FILE}，请先生成或上传！")


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