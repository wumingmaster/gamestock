import os
import sys
import datetime
import traceback
import random

def log(msg):
    print(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}")

def print_all_holdings(Portfolio, user_id):
    log(f"--- 当前数据库 user_id={user_id} 的所有持仓 ---")
    holdings = Portfolio.query.filter_by(user_id=user_id).all()
    if not holdings:
        log("无持仓记录")
    for h in holdings:
        log(f"持仓ID={h.id}, game_id={h.game_id}, shares={h.shares}, avg_buy_price={h.avg_buy_price}, created_at={h.created_at}, updated_at={h.updated_at}")
    log(f"--- 持仓总数: {len(holdings)} ---")

def main():
    log("=== 脚本启动 ===")
    try:
        db_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "instance", "gamestock.db"))
        log(f"数据库绝对路径: {db_path}")
        if not os.path.exists(db_path):
            log(f"❌ 数据库文件不存在: {db_path}")
            sys.exit(1)
        log(f"✅ 数据库文件存在: {db_path}")

        # 2. 导入依赖
        try:
            from app import app, db, Game, User, Portfolio
        except Exception as e:
            log("❌ 依赖导入失败（请检查PYTHONPATH和依赖包）")
            traceback.print_exc()
            sys.exit(1)
        log("✅ 依赖导入成功")

        with app.app_context():
            username = "test_trader"
            user = User.query.filter_by(username=username).first()
            if not user:
                log(f"❌ 用户不存在: {username}")
                sys.exit(1)
            log(f"✅ 用户存在: {username} (id={user.id})")

            # 插入前打印所有持仓
            print_all_holdings(Portfolio, user.id)

            games = Game.query.all()
            if len(games) < 5:
                log(f"❌ 游戏数量不足5个，当前数量: {len(games)}")
                sys.exit(1)
            selected_games = random.sample(games, 5)
            log(f"🎮 选中游戏: {[g.name for g in selected_games]}")

            for game in selected_games:
                holding = Portfolio.query.filter_by(user_id=user.id, game_id=game.id).first()
                if holding:
                    log(f"⚠️ 已有持仓: {game.name} (game_id={game.id})")
                    continue
                price = game.current_price if game.current_price and game.current_price > 0 else 100
                new_holding = Portfolio(
                    user_id=user.id,
                    game_id=game.id,
                    shares=10,
                    avg_buy_price=price
                )
                db.session.add(new_holding)
                log(f"✅ 添加持仓: game_id={game.id}, game_name={game.name}, shares=10, avg_buy_price={price}")

            old_balance = user.balance
            user.balance = 10000
            db.session.commit()
            log(f"✅ 持仓和余额更新完成，原余额: {old_balance}，新余额: {user.balance}")

            # 插入后再次打印所有持仓
            print_all_holdings(Portfolio, user.id)

    except Exception as e:
        log("❌ 脚本执行异常")
        traceback.print_exc()
        sys.exit(1)

    log("=== 脚本结束 ===")

if __name__ == "__main__":
    main() 