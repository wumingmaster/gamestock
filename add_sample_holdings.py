import os
import sys
import datetime
import traceback
import random

def log(msg):
    print(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}")

def main():
    log("=== 脚本启动 ===")
    try:
        # 1. 检查数据库文件
        db_path = os.path.join(os.path.dirname(__file__), "instance", "gamestock.db")
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

        # 关键：所有数据库操作放在app.app_context()下
        with app.app_context():
            # 3. 查找目标用户
            username = "test_trader"
            user = User.query.filter_by(username=username).first()
            if not user:
                log(f"❌ 用户不存在: {username}")
                sys.exit(1)
            log(f"✅ 用户存在: {username} (id={user.id})")

            # 4. 随机选5个游戏
            games = Game.query.all()
            if len(games) < 5:
                log(f"❌ 游戏数量不足5个，当前数量: {len(games)}")
                sys.exit(1)
            selected_games = random.sample(games, 5)
            log(f"🎮 选中游戏: {[g.name for g in selected_games]}")

            # 5. 添加持仓
            for game in selected_games:
                holding = Portfolio.query.filter_by(user_id=user.id, game_id=game.id).first()
                if holding:
                    log(f"⚠️ 已有持仓: {game.name}")
                    continue
                price = game.current_price or 0
                new_holding = Portfolio(
                    user_id=user.id,
                    game_id=game.id,
                    shares=10,
                    avg_buy_price=price,
                    current_price=price,
                    total_value=price * 10,
                    profit_loss=0,
                    profit_loss_percent=0
                )
                db.session.add(new_holding)
                log(f"✅ 添加持仓: {game.name} (10股, 单价: {price})")

            # 6. 设置余额
            old_balance = user.balance
            user.balance = 10000
            db.session.commit()
            log(f"✅ 持仓和余额更新完成，原余额: {old_balance}，新余额: {user.balance}")

    except Exception as e:
        log("❌ 脚本执行异常")
        traceback.print_exc()
        sys.exit(1)

    log("=== 脚本结束 ===")

if __name__ == "__main__":
    main() 