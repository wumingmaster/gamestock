#!/usr/bin/env python3
"""
GameStock iOS - 数据库修复脚本
解决用户认证API的password_hash列缺失问题
"""

import sqlite3
import os

def fix_database():
    """修复数据库schema问题"""
    db_path = "../GameStock/instance/gamestock.db"
    
    if not os.path.exists(db_path):
        print("❌ 数据库文件不存在，请先运行Web应用")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 检查user表结构
        cursor.execute("PRAGMA table_info(user)")
        columns = [col[1] for col in cursor.fetchall()]
        print(f"📊 当前user表列: {columns}")
        
        # 检查是否缺少password_hash列
        if 'password_hash' not in columns:
            print("🔧 添加password_hash列...")
            cursor.execute("ALTER TABLE user ADD COLUMN password_hash TEXT")
            
            # 如果存在password列，复制数据
            if 'password' in columns:
                cursor.execute("UPDATE user SET password_hash = password")
                print("✅ 已复制password到password_hash")
            
        conn.commit()
        conn.close()
        
        print("✅ 数据库修复完成")
        return True
        
    except Exception as e:
        print(f"❌ 数据库修复失败: {str(e)}")
        return False

if __name__ == "__main__":
    print("🔧 GameStock iOS - 数据库修复工具")
    print("=" * 40)
    
    if fix_database():
        print("\n🎉 修复成功！现在可以测试用户认证API了")
        print("💡 重新运行: python3 api_test.py")
    else:
        print("\n⚠️  修复失败，请检查数据库文件路径") 