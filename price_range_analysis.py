#!/usr/bin/env python3
"""
股价公式优化分析
解决股价范围过小和销量影响不足的问题
"""
import math

def current_formula(sales, review_rate):
    """当前公式: log10(销量) × 好评率"""
    return math.log10(sales) * review_rate

def formula_v1(sales, review_rate):
    """方案1: (log10(销量))^1.3 × 好评率 × 15 - 提高销量权重"""
    return (math.log10(sales) ** 1.3) * review_rate * 15

def formula_v2(sales, review_rate):
    """方案2: (log10(销量))^1.5 × 好评率 × 8 - 更强的销量权重"""
    return (math.log10(sales) ** 1.5) * review_rate * 8

def formula_v3(sales, review_rate):
    """方案3: log10(销量)^2 × 好评率 × 2 - 销量平方影响"""
    return (math.log10(sales) ** 2) * review_rate * 2

def formula_v4(sales, review_rate):
    """方案4: log10(销量) × 好评率^0.7 × 25 - 降低好评率权重，提高整体倍数"""
    return math.log10(sales) * (review_rate ** 0.7) * 25

# 测试数据 - 从CSV中选取代表性游戏
test_games = [
    # 极端对比案例
    ("销量巨兽", 135815130, 0.862),  # CS2 - 最高销量
    ("小众精品", 11940, 0.990),      # Helltaker - 最低销量但高好评
    
    # 真实游戏数据
    ("黑神话悟空", 25045110, 0.965),
    ("Wallpaper Engine", 24854280, 0.981),
    ("艾尔登法环", 22962510, 0.930),
    ("赛博朋克2077", 22461690, 0.855),
    ("无人深空", 7980840, 0.815),
    ("永劫无间", 4910760, 0.730),
    ("使命召唤", 11632230, 0.556),  # 高销量低好评
]

print("🎯 股价公式优化分析")
print("=" * 100)
print("目标：股价范围扩大到1-500美元，增强销量影响")
print("=" * 100)

# 先分析销量差异的影响
print("\n📊 销量影响分析:")
print("当前最大销量差异：")
max_sales = max(game[1] for game in test_games)
min_sales = min(game[1] for game in test_games)
sales_ratio = max_sales / min_sales

print(f"最高销量: {max_sales:,}")
print(f"最低销量: {min_sales:,}")
print(f"销量比例: {sales_ratio:.0f}倍")

print(f"\nlog10影响分析:")
print(f"log10({max_sales:,}) = {math.log10(max_sales):.2f}")
print(f"log10({min_sales:,}) = {math.log10(min_sales):.2f}")
print(f"log10差异: {math.log10(max_sales) - math.log10(min_sales):.2f}")
print(f"这意味着{sales_ratio:.0f}倍的销量差异只产生{math.log10(max_sales) - math.log10(min_sales):.2f}倍的价格影响")

print("\n" + "=" * 100)
print("🧪 新公式测试对比")
print("=" * 100)
print(f"{'游戏名称':<15} {'销量':<12} {'好评率':<8} {'当前公式':<10} {'方案1':<8} {'方案2':<8} {'方案3':<8} {'方案4':<8}")
print("-" * 100)

for name, sales, rate in test_games:
    current = current_formula(sales, rate)
    v1 = formula_v1(sales, rate)
    v2 = formula_v2(sales, rate)
    v3 = formula_v3(sales, rate)
    v4 = formula_v4(sales, rate)
    
    print(f"{name:<15} {sales:>10,} {rate*100:>6.1f}% ${current:>8.2f} ${v1:>6.0f} ${v2:>6.0f} ${v3:>6.0f} ${v4:>6.0f}")

print("\n" + "=" * 100)
print("📈 价格范围对比:")
print("=" * 100)

formulas = [
    ("当前公式", current_formula),
    ("方案1", formula_v1),
    ("方案2", formula_v2), 
    ("方案3", formula_v3),
    ("方案4", formula_v4)
]

for formula_name, formula_func in formulas:
    prices = [formula_func(sales, rate) for name, sales, rate in test_games]
    min_price = min(prices)
    max_price = max(prices)
    price_range = max_price - min_price
    price_ratio = max_price / min_price
    
    print(f"{formula_name:<12}: ${min_price:>6.0f} - ${max_price:>6.0f} (范围: ${price_range:>6.0f}, 比例: {price_ratio:>5.1f}倍)")

print("\n" + "=" * 100)
print("💡 销量影响测试 (好评率固定80%):")
print("=" * 100)
print("测试不同销量对股价的影响：")

test_sales = [10000, 100000, 1000000, 10000000, 100000000]
fixed_rate = 0.80

print(f"{'销量':<12} {'当前公式':<10} {'方案1':<8} {'方案2':<8} {'方案3':<8} {'方案4':<8}")
print("-" * 60)

for sales in test_sales:
    current = current_formula(sales, fixed_rate)
    v1 = formula_v1(sales, fixed_rate)
    v2 = formula_v2(sales, fixed_rate)
    v3 = formula_v3(sales, fixed_rate)
    v4 = formula_v4(sales, fixed_rate)
    
    print(f"{sales:>10,} ${current:>8.2f} ${v1:>6.0f} ${v2:>6.0f} ${v3:>6.0f} ${v4:>6.0f}")

print("\n" + "=" * 100)
print("🎯 公式特点分析:")
print("=" * 100)

print("方案1: (log10(销量))^1.3 × 好评率 × 15")
print("• 适度提高销量权重 (指数1.3)")
print("• 保持好评率原始影响")
print("• 价格范围: 合理扩大")

print("\n方案2: (log10(销量))^1.5 × 好评率 × 8")
print("• 显著提高销量权重 (指数1.5)")
print("• 销量差异影响更明显")
print("• 可能过度倾斜向销量")

print("\n方案3: log10(销量)^2 × 好评率 × 2")
print("• 销量影响非常强")
print("• 价格增长较快")
print("• 可能导致小众游戏股价过低")

print("\n方案4: log10(销量) × 好评率^0.7 × 25")
print("• 保持销量log影响")
print("• 降低好评率权重")
print("• 整体倍数提高")

print("\n💰 真实股票价格对比:")
print("目标范围: $1 - $500 (真实股票市场)")
print("当前范围: $3.52 - $7.25")
print("需要扩大约70倍的价格范围")

print("\n🏆 推荐方案:")
print("建议使用方案1：(log10(销量))^1.3 × 好评率 × 15")
print("理由：")
print("• 销量影响增强但不过度")
print("• 价格范围接近真实股票")
print("• 平衡性好，不会过度偏向任一因素")
print("• 便于用户理解和交易") 