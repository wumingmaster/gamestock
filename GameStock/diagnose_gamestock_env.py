import os
import sys
import platform
import time
import subprocess
import traceback
from datetime import datetime
from flask import Flask

LOG_FILE = 'diagnose_log.txt'

def log(msg):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    line = f"[{timestamp}] {msg}"
    print(line)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(line + '\n')

def section(title):
    log('\n' + '='*10 + f' {title} ' + '='*10)

def run_cmd(cmd):
    log(f"$ {cmd}")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        log(result.stdout.strip())
        if result.stderr.strip():
            log('[stderr] ' + result.stderr.strip())
    except Exception as e:
        log(f"[Exception] {e}")

def check_path(path):
    log(f"检查路径: {path}")
    if os.path.exists(path):
        stat = os.stat(path)
        log(f"  存在, 权限: {oct(stat.st_mode)[-3:]}, 大小: {stat.st_size} 字节")
    else:
        log("  [不存在]")

def print_file_head(path, n=20):
    if os.path.exists(path):
        log(f"{path} 前{n}行:")
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            for i, line in enumerate(f):
                if i >= n:
                    break
                log(line.rstrip())
    else:
        log(f"{path} 不存在")

def main():
    # 清空旧日志
    with open(LOG_FILE, 'w', encoding='utf-8') as f:
        f.write('')

    section('环境信息')
    log(f"Python: {sys.version}")
    log(f"Platform: {platform.platform()}")
    log(f"当前目录: {os.getcwd()}")
    log(f"虚拟环境: {os.environ.get('VIRTUAL_ENV', '未激活')}")

    section('依赖版本')
    run_cmd('pip freeze')

    section('关键路径检查')
    BASE = '/root/GameStock'
    DB_FILE = f'{BASE}/instance/gamestock.db'
    CSV_FILE = f'{BASE}/GameStock/steam_games_backup.csv'
    INSTANCE_DIR = f'{BASE}/instance'
    check_path(BASE)
    check_path(DB_FILE)
    check_path(CSV_FILE)
    check_path(INSTANCE_DIR)

    section('数据库表结构 (sqlite3 .schema game)')
    if os.path.exists(DB_FILE):
        run_cmd(f'sqlite3 {DB_FILE} ".schema game"')
    else:
        log(f"数据库文件不存在: {DB_FILE}")

    section('Game模型定义源码')
    # 自动查找 models.py
    model_path = None
    for root, dirs, files in os.walk(BASE):
        for f in files:
            if f == 'models.py':
                model_path = os.path.join(root, f)
                break
    if model_path:
        print_file_head(model_path, 60)
    else:
        log('未找到 models.py')

    section('SQLAlchemy 查询测试')
    try:
        from models import db, Game
        app = Flask(__name__)
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////root/GameStock/instance/gamestock.db'
        db.init_app(app)
        with app.app_context():
            log('尝试查询一条 Game 记录...')
            game = Game.query.first()
            if game:
                log(f'Game: id={game.id}, steam_id={getattr(game, "steam_id", None)}, name={game.name}')
            else:
                log('Game表为空')
    except Exception as e:
        log('SQLAlchemy 查询异常:')
        log(traceback.format_exc())

    section('requirements.txt 内容')
    req_path = os.path.join(BASE, 'requirements.txt')
    print_file_head(req_path, 30)

    section('诊断结束')
    log('请将 diagnose_log.txt 全部内容贴给AI分析！')

if __name__ == '__main__':
    main() 