#!/usr/bin/env python3
"""
导入CSV游戏数据到数据库
"""
import csv
import sys
from app import app, db, Game
from datetime import datetime

def import_games_from_csv(csv_file='gamestock_positive_reviews_20250602_150236.csv'):
    """从CSV文件导入游戏数据"""
    
    with app.app_context():
        print(f"🎮 开始导入游戏数据从: {csv_file}")
        
        # 读取CSV文件
        games_added = 0
        games_updated = 0
        
        with open(csv_file, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            
            for row in reader:
                steam_id = row['Steam_ID']
                name = row['游戏名称']
                positive_reviews = int(row['好评数'].replace(',', ''))
                total_reviews = int(row['总评论数'].replace(',', ''))
                review_rate = float(row['好评率'].replace('%', '')) / 100
                sales_count = int(row['估算销量'].replace(',', ''))
                
                # 计算股价 (使用基于好评数的公式)
                import math
                current_price = (math.log10(positive_reviews))**1.3 * (review_rate)**0.5 * 20
                
                # 检查游戏是否已存在
                existing_game = Game.query.filter_by(steam_id=steam_id).first()
                
                if existing_game:
                    # 更新现有游戏
                    existing_game.name = name
                    existing_game.positive_reviews = positive_reviews
                    existing_game.total_reviews = total_reviews
                    existing_game.sales_count = sales_count
                    existing_game.current_price = current_price
                    existing_game.last_updated = datetime.utcnow()
                    games_updated += 1
                    print(f"📝 更新游戏: {name} (${current_price:.2f})")
                else:
                    # 添加新游戏
                    new_game = Game(
                        name=name,
                        steam_id=steam_id,
                        positive_reviews=positive_reviews,
                        total_reviews=total_reviews,
                        sales_count=sales_count,
                        last_updated=datetime.utcnow()
                    )
                    db.session.add(new_game)
                    games_added += 1
                    print(f"➕ 添加游戏: {name} (${current_price:.2f})")
        
        # 提交所有更改
        try:
            db.session.commit()
            print(f"\n✅ 导入完成!")
            print(f"📊 添加了 {games_added} 个新游戏")
            print(f"📊 更新了 {games_updated} 个现有游戏")
            print(f"📊 总计: {games_added + games_updated} 个游戏")
            
            # 显示前10个游戏
            print(f"\n🏆 股价排行榜前10名:")
            top_games = Game.query.order_by(Game.current_price.desc()).limit(10).all()
            for i, game in enumerate(top_games, 1):
                print(f"{i:2d}. {game.name:<30} ${game.current_price:>8.2f}")
                
        except Exception as e:
            db.session.rollback()
            print(f"❌ 导入失败: {e}")
            return False
    
    return True

if __name__ == "__main__":
    success = import_games_from_csv()
    if not success:
        sys.exit(1)
    print(f"\n🎉 所有游戏数据已成功导入数据库!") 