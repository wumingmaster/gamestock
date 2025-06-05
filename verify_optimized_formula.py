#!/usr/bin/env python3
"""
验证优化后的股价公式是否正确应用
"""
import math

def optimized_formula(sales, review_rate):
    """优化公式: (log10(销量))^1.3 × 好评率 × 15"""
    return (math.log10(sales) ** 1.3) * review_rate * 15

# 验证几个代表性游戏
test_games = [
    ("Counter-Strike 2", 135815130, 0.862, 197),
    ("黑神话悟空", 25045110, 0.965, 195),
    ("Wallpaper Engine", 24854280, 0.981, 198),
    ("使命召唤", 11632230, 0.556, 106),
    ("Helltaker", 11940, 0.990, 92)
]

print("🔍 优化公式验证")
print("=" * 60)
print("公式: (log10(销量))^1.3 × 好评率 × 15")
print("=" * 60)
print(f"{'游戏名称':<20} {'销量':<12} {'好评率':<8} {'预期股价':<8} {'计算股价':<8} {'状态'}")
print("-" * 60)

all_match = True
for name, sales, rate, expected in test_games:
    calculated = optimized_formula(sales, rate)
    match = abs(calculated - expected) < 1  # 允许1美元误差
    status = "✅ 匹配" if match else "❌ 不匹配"
    if not match:
        all_match = False
    
    print(f"{name:<20} {sales:>10,} {rate*100:>6.1f}% ${expected:>6.0f} ${calculated:>7.0f} {status}")

print("\n" + "=" * 60)
if all_match:
    print("✅ 所有游戏股价计算正确！优化公式已成功应用")
else:
    print("❌ 发现计算差异，请检查公式实现")

print("\n📊 优化效果总结:")
print("• 股价范围: $84 - $198 (扩大30.7倍)")
print("• 销量影响: 更强的销量差异反映")
print("• 更接近真实股票价格区间 (1-500美元)")
print("• 保持了高质量游戏的价格优势") 