import requests
import json

def get_stock_rankings():
    """获取股票排行榜"""
    try:
        response = requests.get("http://localhost:5001/api/games")
        if response.status_code == 200:
            games = response.json()
            # 按股价排序
            games.sort(key=lambda x: x['current_price'], reverse=True)
            return games
        else:
            print(f"API请求失败: {response.status_code}")
            return []
    except Exception as e:
        print(f"连接错误: {e}")
        return []

def display_rankings(games, top_n=20):
    """显示股价排行榜"""
    print("🎯 GameStock 股价排行榜 - 新公式验证")
    print("="*80)
    print(f"{'排名':<4} {'游戏名称':<25} {'股价':<10} {'销量':<12} {'好评率':<8} {'档次'}")
    print("-"*80)
    
    for i, game in enumerate(games[:top_n]):
        price = game['current_price']
        sales = game['sales_count']
        rate = game['review_rate'] * 100
        
        # 判断档次
        if price >= 50:
            tier = "🔥🔥🔥🔥"
        elif price >= 40:
            tier = "🔥🔥🔥"
        elif price >= 30:
            tier = "🔥🔥"
        elif price >= 20:
            tier = "🔥"
        else:
            tier = "⭐"
            
        # 判断销量档次
        if sales >= 10000000:
            sales_tier = "千万级"
        elif sales >= 5000000:
            sales_tier = "五百万级"
        elif sales >= 2000000:
            sales_tier = "二百万级"
        elif sales >= 500000:
            sales_tier = "五十万级"
        elif sales >= 100000:
            sales_tier = "十万级"
        elif sales >= 10000:
            sales_tier = "万级"
        else:
            sales_tier = "千级"
        
        print(f"{i+1:<4} {game['name'][:24]:<25} ${price:>7.2f}   {sales:>10,} {rate:>6.1f}% {tier}")

    print("\n📊 股价分布统计:")
    prices = [g['current_price'] for g in games]
    if prices:
        print(f"最高股价: ${max(prices):.2f}")
        print(f"最低股价: ${min(prices):.2f}")
        print(f"价格跨度: ${max(prices) - min(prices):.2f}")
        print(f"平均股价: ${sum(prices)/len(prices):.2f}")
        
        # 各档次分布
        tiers = {"🔥🔥🔥🔥": 0, "🔥🔥🔥": 0, "🔥🔥": 0, "🔥": 0, "⭐": 0}
        for price in prices:
            if price >= 50:
                tiers["🔥🔥🔥🔥"] += 1
            elif price >= 40:
                tiers["🔥🔥🔥"] += 1
            elif price >= 30:
                tiers["🔥🔥"] += 1
            elif price >= 20:
                tiers["🔥"] += 1
            else:
                tiers["⭐"] += 1
                
        print(f"\n档次分布:")
        for tier, count in tiers.items():
            print(f"{tier} 档次: {count} 个游戏")

if __name__ == "__main__":
    games = get_stock_rankings()
    if games:
        display_rankings(games)
        print(f"\n总共 {len(games)} 个游戏在市场交易")
    else:
        print("❌ 无法获取游戏数据") 