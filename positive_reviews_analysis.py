#!/usr/bin/env python3
"""
好评数替代销量的公式分析
解决销量数据不准确的问题，使用精确的好评数数据
"""
import math
import csv
import glob

def current_formula(sales, review_rate):
    """当前公式: (log10(销量))^1.3 × 好评率 × 15"""
    return (math.log10(sales) ** 1.3) * review_rate * 15

def positive_reviews_v1(positive_reviews, review_rate):
    """方案1: (log10(好评数))^1.3 × 好评率 × 15 - 直接替换"""
    return (math.log10(positive_reviews) ** 1.3) * review_rate * 15

def positive_reviews_v2(positive_reviews, review_rate):
    """方案2: (log10(好评数))^1.4 × 25 - 只用好评数，不重复计算好评率"""
    return (math.log10(positive_reviews) ** 1.4) * 25

def positive_reviews_v3(positive_reviews, review_rate):
    """方案3: (log10(好评数))^1.3 × (好评率)^0.5 × 20 - 降低好评率权重"""
    return (math.log10(positive_reviews) ** 1.3) * (review_rate ** 0.5) * 20

def positive_reviews_v4(positive_reviews, review_rate):
    """方案4: (log10(好评数))^1.2 × (好评率)^0.8 × 18 - 平衡版本"""
    return (math.log10(positive_reviews) ** 1.2) * (review_rate ** 0.8) * 18

def read_game_data():
    """读取游戏数据"""
    csv_files = glob.glob("gamestock_data_*.csv")
    if not csv_files:
        print("❌ 未找到CSV数据文件")
        return []
    
    latest_file = max(csv_files)
    print(f"📁 读取数据: {latest_file}")
    
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
                'review_rate': float(row['好评率'].replace('%', '')) / 100
            })
    
    return games

def main():
    """主函数"""
    print("🎯 好评数替代销量的公式分析")
    print("=" * 80)
    print("问题：Steam API无法获得准确销量，只能估算")
    print("解决：使用精确的好评数替代不准确的估算销量")
    print("=" * 80)
    
    games = read_game_data()
    if not games:
        return
    
    print(f"✅ 读取了 {len(games)} 款游戏数据\n")
    
    # 数据分析
    print("📊 数据精确性对比:")
    print("-" * 60)
    print(f"{'数据类型':<15} {'数据来源':<20} {'精确性'}")
    print("-" * 60)
    print(f"{'销量':<15} {'评论数×30估算':<20} {'❌ 不准确'}")
    print(f"{'好评数':<15} {'Steam API直接获取':<20} {'✅ 精确'}")
    print(f"{'好评率':<15} {'好评数/总评论数':<20} {'✅ 精确'}")
    
    # 数据范围分析
    sales_data = [g['sales'] for g in games]
    positive_data = [g['positive_reviews'] for g in games]
    
    print(f"\n📈 数据范围对比:")
    print("-" * 60)
    print(f"估算销量范围: {min(sales_data):,} - {max(sales_data):,}")
    print(f"好评数范围: {min(positive_data):,} - {max(positive_data):,}")
    print(f"销量/好评数比值: {min(sales_data)/min(positive_data):.1f} - {max(sales_data)/max(positive_data):.1f}")
    
    # 公式影响分析
    print(f"\n⚠️  公式调整考虑:")
    print("当前公式使用好评率的逻辑：")
    print("• 销量 × 好评率 = 体现质量对市值的影响")
    print("• 好评数 = 总评论数 × 好评率")
    print("• 如果用好评数×好评率，等于好评率被计算了两次")
    print("\n需要调整公式避免重复计算好评率影响")
    
    # 测试不同公式方案
    print(f"\n🧪 新公式方案测试:")
    print("=" * 80)
    print(f"{'游戏名称':<15} {'好评数':<10} {'好评率':<8} {'当前':<8} {'方案1':<8} {'方案2':<8} {'方案3':<8} {'方案4':<8}")
    print("-" * 80)
    
    for game in games[:8]:  # 显示前8个游戏
        name = game['name'][:14]  # 截断过长名称
        pos_reviews = game['positive_reviews']
        rate = game['review_rate']
        sales = game['sales']
        
        current = current_formula(sales, rate)
        v1 = positive_reviews_v1(pos_reviews, rate) if pos_reviews > 0 else 0
        v2 = positive_reviews_v2(pos_reviews, rate) if pos_reviews > 0 else 0
        v3 = positive_reviews_v3(pos_reviews, rate) if pos_reviews > 0 else 0
        v4 = positive_reviews_v4(pos_reviews, rate) if pos_reviews > 0 else 0
        
        print(f"{name:<15} {pos_reviews:>8,} {rate*100:>6.1f}% ${current:>6.0f} ${v1:>6.0f} ${v2:>6.0f} ${v3:>6.0f} ${v4:>6.0f}")
    
    # 价格范围分析
    print(f"\n📈 价格范围对比:")
    print("=" * 80)
    
    formulas = [
        ("当前公式(销量)", lambda g: current_formula(g['sales'], g['review_rate'])),
        ("方案1(直接替换)", lambda g: positive_reviews_v1(g['positive_reviews'], g['review_rate']) if g['positive_reviews'] > 0 else 0),
        ("方案2(只用好评数)", lambda g: positive_reviews_v2(g['positive_reviews'], g['review_rate']) if g['positive_reviews'] > 0 else 0),
        ("方案3(降低好评率权重)", lambda g: positive_reviews_v3(g['positive_reviews'], g['review_rate']) if g['positive_reviews'] > 0 else 0),
        ("方案4(平衡版本)", lambda g: positive_reviews_v4(g['positive_reviews'], g['review_rate']) if g['positive_reviews'] > 0 else 0)
    ]
    
    for formula_name, formula_func in formulas:
        prices = [formula_func(game) for game in games]
        min_price = min(prices)
        max_price = max(prices)
        price_range = max_price - min_price
        price_ratio = max_price / min_price if min_price > 0 else 0
        
        print(f"{formula_name:<20}: ${min_price:>6.0f} - ${max_price:>6.0f} (范围: ${price_range:>6.0f}, 比例: {price_ratio:>5.1f}倍)")
    
    # 好评数影响测试
    print(f"\n💡 好评数影响测试 (好评率固定80%):")
    print("=" * 60)
    test_positive_reviews = [1000, 10000, 100000, 1000000, 5000000]
    fixed_rate = 0.80
    
    print(f"{'好评数':<12} {'方案2':<8} {'方案3':<8} {'方案4':<8}")
    print("-" * 40)
    
    for pos_reviews in test_positive_reviews:
        v2 = positive_reviews_v2(pos_reviews, fixed_rate)
        v3 = positive_reviews_v3(pos_reviews, fixed_rate)
        v4 = positive_reviews_v4(pos_reviews, fixed_rate)
        
        print(f"{pos_reviews:>10,} ${v2:>6.0f} ${v3:>6.0f} ${v4:>6.0f}")
    
    print(f"\n🎯 推荐方案分析:")
    print("=" * 80)
    
    print("方案1 (直接替换): (log10(好评数))^1.3 × 好评率 × 15")
    print("• 问题: 好评率被重复计算，高好评率游戏获得过度优势")
    print("• 适用: 如果希望质量因素占主导地位")
    
    print("\n方案2 (只用好评数): (log10(好评数))^1.4 × 25")
    print("• 优势: 避免重复计算，逻辑清晰")
    print("• 考虑: 完全忽略好评率差异")
    print("• 适用: 如果认为好评数已经体现了质量")
    
    print("\n方案3 (降低好评率权重): (log10(好评数))^1.3 × (好评率)^0.5 × 20")
    print("• 优势: 平衡好评数和好评率影响")
    print("• 逻辑: 好评数为主要因素，好评率为调节因素")
    print("• 适用: 希望保持质量影响但避免重复计算")
    
    print("\n方案4 (平衡版本): (log10(好评数))^1.2 × (好评率)^0.8 × 18")
    print("• 优势: 更温和的调整，保持较强的质量影响")
    print("• 逻辑: 好评数和好评率都有合理权重")
    print("• 适用: 渐进式改进，风险较小")
    
    print(f"\n🏆 最终推荐:")
    print("建议使用方案3：(log10(好评数))^1.3 × (好评率)^0.5 × 20")
    print("理由：")
    print("• 解决了数据准确性问题（使用精确的好评数）")
    print("• 避免了好评率的重复计算")
    print("• 保持了质量因素的影响（好评率^0.5）")
    print("• 价格范围合理，符合股票市场体验")

if __name__ == "__main__":
    main() 