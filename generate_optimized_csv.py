#!/usr/bin/env python3
"""
使用优化公式重新生成GameStock游戏数据CSV
"""
import csv
import math
from datetime import datetime

def optimized_stock_price(sales_count, review_rate):
    """优化股价公式: (log10(销量))^1.3 × 好评率 × 15"""
    if sales_count <= 0:
        return 0.0
    return (math.log10(sales_count) ** 1.3) * review_rate * 15

def read_original_csv():
    """读取原始CSV数据"""
    import glob
    csv_files = glob.glob("gamestock_data_*.csv")
    if not csv_files:
        print("❌ 未找到原始CSV数据文件")
        return []
    
    latest_file = max(csv_files)
    print(f"📁 读取原始数据: {latest_file}")
    
    games = []
    with open(latest_file, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            games.append({
                'name': row['游戏名称'],
                'steam_id': row['Steam_ID'],
                'sales': int(row['估算销量']),
                'positive_reviews': int(row['好评数']),
                'total_reviews': int(row['总评论数']),
                'review_rate': float(row['好评率'].replace('%', '')) / 100,
                'old_stock_price': float(row['股价'].replace('$', ''))
            })
    
    return games

def main():
    """主函数：重新计算股价并生成优化CSV"""
    print("🚀 GameStock股价公式优化")
    print("=" * 60)
    print("新公式: (log10(销量))^1.3 × 好评率 × 15")
    print("目标: 扩大股价范围，增强销量影响")
    print("=" * 60)
    
    # 读取原始数据
    games = read_original_csv()
    if not games:
        return
    
    print(f"✅ 读取了 {len(games)} 款游戏数据")
    
    # 重新计算股价
    for game in games:
        game['new_stock_price'] = optimized_stock_price(game['sales'], game['review_rate'])
    
    # 按新股价排序
    games.sort(key=lambda x: x['new_stock_price'], reverse=True)
    
    # 生成优化后的CSV文件
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"gamestock_optimized_{timestamp}.csv"
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['排名', '游戏名称', 'Steam_ID', '估算销量', '好评数', '总评论数', '好评率', '原股价', '新股价', '价格变化']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for i, game in enumerate(games, 1):
            price_change = game['new_stock_price'] - game['old_stock_price']
            change_percent = (price_change / game['old_stock_price']) * 100
            
            writer.writerow({
                '排名': i,
                '游戏名称': game['name'],
                'Steam_ID': game['steam_id'],
                '估算销量': game['sales'],
                '好评数': game['positive_reviews'],
                '总评论数': game['total_reviews'],
                '好评率': f"{game['review_rate']:.1%}",
                '原股价': f"${game['old_stock_price']:.2f}",
                '新股价': f"${game['new_stock_price']:.0f}",
                '价格变化': f"+${price_change:.0f} ({change_percent:+.0f}%)"
            })
    
    print(f"\n📁 优化数据已保存到: {filename}")
    
    # 显示对比分析
    print("\n🎯 股价优化效果分析:")
    print("=" * 60)
    
    old_prices = [game['old_stock_price'] for game in games]
    new_prices = [game['new_stock_price'] for game in games]
    
    print(f"原股价范围: ${min(old_prices):.2f} - ${max(old_prices):.2f}")
    print(f"新股价范围: ${min(new_prices):.0f} - ${max(new_prices):.0f}")
    print(f"价格范围扩大: {(max(new_prices) - min(new_prices)) / (max(old_prices) - min(old_prices)):.1f}倍")
    
    print(f"\n🏆 新股价排行榜 (前10名):")
    print("-" * 60)
    for i, game in enumerate(games[:10], 1):
        old_rank = sorted(games, key=lambda x: x['old_stock_price'], reverse=True).index(game) + 1
        rank_change = old_rank - i
        rank_indicator = "📈" if rank_change > 0 else "📉" if rank_change < 0 else "➡️"
        
        print(f"{i:2d}. {game['name']:<25} ${game['new_stock_price']:>3.0f} "
              f"(原${game['old_stock_price']:>5.2f}) {rank_indicator}")
    
    print(f"\n💡 销量影响增强测试:")
    print("-" * 60)
    
    # 找出销量差异最大的两款游戏对比
    highest_sales = max(games, key=lambda x: x['sales'])
    lowest_sales = min(games, key=lambda x: x['sales'])
    
    sales_ratio = highest_sales['sales'] / lowest_sales['sales']
    old_price_ratio = highest_sales['old_stock_price'] / lowest_sales['old_stock_price']
    new_price_ratio = highest_sales['new_stock_price'] / lowest_sales['new_stock_price']
    
    print(f"销量差异: {sales_ratio:.0f}倍")
    print(f"原股价差异: {old_price_ratio:.1f}倍")
    print(f"新股价差异: {new_price_ratio:.1f}倍")
    print(f"销量影响增强: {new_price_ratio / old_price_ratio:.1f}倍")
    
    print(f"\n✅ 优化完成！新公式显著提升了销量的影响力")
    print(f"股价范围更接近真实股票市场的1-500美元区间")

if __name__ == "__main__":
    main() 