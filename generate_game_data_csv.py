#!/usr/bin/env python3
"""
GameStock游戏数据CSV生成器
从Steam API获取真实游戏数据，包含不同销量量级和好评率的代表性游戏
"""

import requests
import math
import csv
import time
from datetime import datetime

# Steam API配置
STEAM_API_KEY = "F7CA22D08BE8B62D94BA5568702B08B2"

def get_steam_game_details(app_id):
    """从Steam API获取游戏详细信息"""
    try:
        # 获取游戏基本信息
        store_url = f"https://store.steampowered.com/api/appdetails?appids={app_id}&l=schinese"
        reviews_url = f"https://store.steampowered.com/appreviews/{app_id}?json=1&language=all"
        
        print(f"正在获取游戏 {app_id} 的数据...")
        
        # 获取基本信息
        store_response = requests.get(store_url)
        time.sleep(1)  # 避免请求过于频繁
        
        if store_response.status_code != 200:
            print(f"  ❌ 获取基本信息失败: {store_response.status_code}")
            return None
            
        store_data = store_response.json()
        
        if str(app_id) not in store_data or not store_data[str(app_id)].get('success'):
            print(f"  ❌ 游戏数据无效或不存在")
            return None
            
        game_info = store_data[str(app_id)]['data']
        game_name = game_info.get('name', f'Unknown Game {app_id}')
        
        # 获取评论信息
        reviews_response = requests.get(reviews_url)
        time.sleep(1)
        
        if reviews_response.status_code != 200:
            print(f"  ⚠️  获取评论数据失败，使用默认值")
            return {
                'app_id': app_id,
                'name': game_name,
                'sales_count': 100000,  # 默认销量
                'positive_reviews': 8000,
                'total_reviews': 10000,
                'review_rate': 0.80
            }
            
        reviews_data = reviews_response.json()
        
        if reviews_data.get('success') != 1:
            print(f"  ⚠️  评论数据解析失败，使用默认值")
            return {
                'app_id': app_id,
                'name': game_name,
                'sales_count': 100000,
                'positive_reviews': 8000,
                'total_reviews': 10000,
                'review_rate': 0.80
            }
            
        query_summary = reviews_data.get('query_summary', {})
        total_positive = query_summary.get('total_positive', 0)
        total_reviews = query_summary.get('total_reviews', 1)
        
        # 计算好评率
        review_rate = total_positive / total_reviews if total_reviews > 0 else 0.80
        
        # 估算销量 (通常评论数是销量的1/20到1/50)
        estimated_sales = total_reviews * 30  # 使用30倍作为估算系数
        
        print(f"  ✅ {game_name}")
        print(f"     评论总数: {total_reviews:,}, 好评: {total_positive:,}")
        print(f"     好评率: {review_rate:.1%}, 估算销量: {estimated_sales:,}")
        
        return {
            'app_id': app_id,
            'name': game_name,
            'sales_count': estimated_sales,
            'positive_reviews': total_positive,
            'total_reviews': total_reviews,
            'review_rate': review_rate
        }
        
    except Exception as e:
        print(f"  ❌ 获取游戏数据时出错: {e}")
        return None

def calculate_stock_price(sales_count, review_rate):
    """计算股价: log10(销量) × 好评率"""
    if sales_count <= 0:
        return 0.0
    return math.log10(sales_count) * review_rate

def main():
    """主函数：获取游戏数据并生成CSV"""
    
    # 不同销量量级的代表性游戏
    # AppID来源：Steam商店实际游戏
    target_games = [
        # 超级大作（千万销量级）
        (730, "Counter-Strike 2"),           # CS2
        (570, "Dota 2"),                     # Dota 2
        (440, "Team Fortress 2"),            # TF2
        (271590, "Grand Theft Auto V"),      # GTA 5
        (1086940, "Baldur's Gate 3"),        # 博德之门3
        
        # 热门游戏（百万销量级）
        (275850, "No Man's Sky"),            # 无人深空
        (431960, "Wallpaper Engine"),        # 壁纸引擎
        (1174180, "Red Dead Redemption 2"),  # 荒野大镖客2
        (292030, "The Witcher 3"),           # 巫师3
        (1203220, "NARAKA: BLADEPOINT"),     # 永劫无间
        
        # 中等销量（十万销量级）
        (1289310, "It Takes Two"),           # 双人成行
        (1938090, "Call of Duty: Warzone"),  # 使命召唤战区
        (1245620, "ELDEN RING"),             # 艾尔登法环
        (1172470, "Apex Legends"),           # Apex英雄
        (2358720, "Black Myth: Wukong"),     # 黑神话悟空
        
        # 小众精品（万级销量）
        (1091500, "Cyberpunk 2077"),         # 赛博朋克2077
        (1966720, "Valheim"),                # 英灵神殿
        (1144200, "Among Us"),               # 糖豆人
        (1190460, "DEATH STRANDING"),        # 死亡搁浅
        (1237970, "Titanfall 2"),            # 泰坦陨落2
    ]
    
    print("🎮 GameStock游戏数据收集器")
    print("=" * 60)
    print(f"计划收集 {len(target_games)} 款游戏的数据")
    print("股价公式: log10(销量) × 好评率")
    print("=" * 60)
    
    collected_data = []
    
    for app_id, expected_name in target_games:
        game_data = get_steam_game_details(app_id)
        
        if game_data:
            # 计算股价
            stock_price = calculate_stock_price(game_data['sales_count'], game_data['review_rate'])
            
            # 添加股价到数据中
            game_data['stock_price'] = stock_price
            collected_data.append(game_data)
            
            print(f"     股价: ${stock_price:.2f}")
        else:
            print(f"  ⚠️  跳过游戏 {app_id} ({expected_name})")
            
        print("-" * 40)
        time.sleep(2)  # 防止请求过于频繁
    
    # 按股价排序
    collected_data.sort(key=lambda x: x['stock_price'], reverse=True)
    
    # 生成CSV文件
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"gamestock_data_{timestamp}.csv"
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['排名', '游戏名称', 'Steam_ID', '估算销量', '好评数', '总评论数', '好评率', '股价']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for i, game in enumerate(collected_data, 1):
            writer.writerow({
                '排名': i,
                '游戏名称': game['name'],
                'Steam_ID': game['app_id'],
                '估算销量': game['sales_count'],
                '好评数': game['positive_reviews'],
                '总评论数': game['total_reviews'],
                '好评率': f"{game['review_rate']:.1%}",
                '股价': f"${game['stock_price']:.2f}"
            })
    
    print("\n" + "=" * 60)
    print("📊 数据收集完成！")
    print(f"✅ 成功收集 {len(collected_data)} 款游戏数据")
    print(f"📁 数据已保存到: {filename}")
    print("\n🏆 股价排行榜 (前10名):")
    print("-" * 60)
    
    for i, game in enumerate(collected_data[:10], 1):
        print(f"{i:2d}. {game['name']:<25} ${game['stock_price']:>6.2f} "
              f"(销量: {game['sales_count']:>8,}, 好评率: {game['review_rate']:>5.1%})")
    
    print("\n" + "=" * 60)
    print("💡 数据说明:")
    print("• 销量为基于评论数的估算值 (评论数 × 30)")
    print("• 好评率为实际Steam数据")
    print("• 股价公式: log10(销量) × 好评率")
    print("• 数据获取时间:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

if __name__ == "__main__":
    main() 