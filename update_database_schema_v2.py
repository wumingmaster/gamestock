#!/usr/bin/env python3
"""
GameStock 数据库架构更新脚本 v2
添加游戏图标和多语言名称支持
"""

import sqlite3
import os
from datetime import datetime

def update_database_schema():
    """更新数据库架构，添加新字段"""
    
    # 数据库文件路径
    db_path = 'instance/gamestock.db'
    if not os.path.exists(db_path):
        print("❌ 数据库文件不存在")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("🔧 开始更新数据库架构...")
        
        # 检查现有字段
        cursor.execute("PRAGMA table_info(game)")
        existing_columns = [column[1] for column in cursor.fetchall()]
        print(f"📋 现有字段: {existing_columns}")
        
        # 需要添加的新字段
        new_columns = [
            ('name_zh', 'VARCHAR(200)', '中文名称'),
            ('icon_url', 'VARCHAR(500)', '游戏图标URL'),
            ('header_image', 'VARCHAR(500)', '游戏头图URL')
        ]
        
        # 添加新字段
        for column_name, column_type, description in new_columns:
            if column_name not in existing_columns:
                try:
                    sql = f"ALTER TABLE game ADD COLUMN {column_name} {column_type}"
                    cursor.execute(sql)
                    print(f"✅ 成功添加字段: {column_name} ({description})")
                except sqlite3.Error as e:
                    print(f"❌ 添加字段 {column_name} 失败: {e}")
            else:
                print(f"⚠️ 字段 {column_name} 已存在，跳过")
        
        conn.commit()
        print("\n🎉 数据库架构更新完成！")
        
        # 验证更新结果
        cursor.execute("PRAGMA table_info(game)")
        updated_columns = [column[1] for column in cursor.fetchall()]
        print(f"📋 更新后字段: {updated_columns}")
        
        # 检查数据行数
        cursor.execute("SELECT COUNT(*) FROM game")
        game_count = cursor.fetchone()[0]
        print(f"📊 当前游戏数量: {game_count}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ 数据库更新失败: {e}")
        return False

if __name__ == "__main__":
    print("🚀 GameStock 数据库架构更新工具 v2")
    print("=" * 50)
    
    success = update_database_schema()
    
    if success:
        print("\n✨ 数据库已成功更新，现在支持：")
        print("  📝 多语言游戏名称 (中文/英文)")
        print("  🎮 真实游戏图标显示")
        print("  🖼️ 游戏头图展示")
        print("\n🔄 请重启应用以生效")
    else:
        print("\n💥 更新失败，请检查错误信息") 