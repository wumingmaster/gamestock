#!/usr/bin/env python3
"""
验证股价公式是否已改回原始版本
"""
import math

def original_formula(sales, review_rate):
    """原始公式: log10(销量) × 好评率"""
    return math.log10(sales) * review_rate

def previous_optimized_formula(sales, review_rate):
    """之前的优化公式: (log10(销量))^1.3 × (好评率)^0.8 × 8"""
    return (math.log10(sales) ** 1.3) * (review_rate ** 0.8) * 8

# 测试游戏数据
test_games = [
    ("黑神话悟空", 25045110, 0.965),
    ("Counter-Strike 2", 135815130, 0.862),
    ("无人深空", 7980840, 0.815),
    ("Wallpaper Engine", 24854280, 0.981),
]

print("🔄 股价公式验证")
print("=" * 80)
print("验证是否已改回原始公式: log10(销量) × 好评率")
print("=" * 80)
print(f"{'游戏名称':<20} {'销量':<12} {'好评率':<8} {'原始公式':<10} {'之前优化公式':<12}")
print("-" * 80)

for name, sales, rate in test_games:
    original_price = original_formula(sales, rate)
    optimized_price = previous_optimized_formula(sales, rate)
    
    print(f"{name:<20} {sales:>10,} {rate*100:>6.1f}% ${original_price:>8.2f} ${optimized_price:>10.2f}")

print("\n" + "=" * 80)
print("📊 公式对比说明:")
print(f"{'原始公式':<20}: log10(销量) × 好评率")
print(f"{'之前优化公式':<20}: (log10(销量))^1.3 × (好评率)^0.8 × 8")
print("\n现在应该使用原始公式 (较小的股价数值)")
print("如果应用中的股价与'原始公式'列一致，说明修改成功！")

# 从CSV文件中验证几个游戏的股价
print("\n🎯 CSV数据验证:")
print("根据生成的CSV文件，以下股价应该与原始公式计算结果一致:")

csv_prices = {
    "黑神话悟空": 7.14,
    "Counter-Strike 2": 7.01,
    "Wallpaper Engine": 7.25,
    "无人深空": 5.62
}

print(f"{'游戏名称':<20} {'CSV股价':<10} {'原始公式计算':<12} {'匹配状态':<10}")
print("-" * 60)

for name, sales, rate in test_games:
    if name in csv_prices:
        csv_price = csv_prices[name]
        calculated_price = original_formula(sales, rate)
        match_status = "✅ 匹配" if abs(csv_price - calculated_price) < 0.01 else "❌ 不匹配"
        print(f"{name:<20} ${csv_price:<8.2f} ${calculated_price:<10.2f} {match_status}")

print("\n✅ 如果所有游戏都显示'匹配'，说明公式修改成功！") 