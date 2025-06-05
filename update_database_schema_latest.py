#!/usr/bin/env python3
"""
GameStock 数据库模式更新脚本 - 最新版本
添加缺失的字段到Game表：name_zh, icon_url, header_image, data_accuracy, api_status
"""

import sqlite3
import os
from datetime import datetime

def update_database_schema():
    """更新数据库模式，添加缺失的字段"""
    
    # 数据库文件路径
    db_path = os.path.join(os.path.dirname(__file__), 'instance', 'gamestock.db')
    
    if not os.path.exists(db_path):
        print("❌ 数据库文件不存在，请先运行应用创建数据库")
        return False
    
    print("🔧 开始更新数据库模式...")
    print(f"📂 数据库路径: {db_path}")
    
    try:
        # 连接数据库
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 检查当前表结构
        cursor.execute("PRAGMA table_info(game)")
        existing_columns = [column[1] for column in cursor.fetchall()]
        print(f"📋 当前字段: {existing_columns}")
        
        # 需要添加的字段列表
        new_columns = [
            ('name_zh', 'TEXT'),
            ('icon_url', 'TEXT'),
            ('header_image', 'TEXT'),
            ('data_accuracy', 'TEXT', 'unknown'),
            ('api_status', 'TEXT', 'not_checked')
        ]
        
        # 添加缺失的字段
        added_columns = []
        for column_info in new_columns:
            column_name = column_info[0]
            column_type = column_info[1]
            default_value = column_info[2] if len(column_info) > 2 else None
            
            if column_name not in existing_columns:
                try:
                    if default_value:
                        sql = f"ALTER TABLE game ADD COLUMN {column_name} {column_type} DEFAULT '{default_value}'"
                    else:
                        sql = f"ALTER TABLE game ADD COLUMN {column_name} {column_type}"
                    
                    cursor.execute(sql)
                    added_columns.append(column_name)
                    print(f"✅ 添加字段: {column_name} ({column_type})")
                    
                except sqlite3.OperationalError as e:
                    print(f"⚠️ 字段 {column_name} 可能已存在: {e}")
            else:
                print(f"ℹ️ 字段 {column_name} 已存在，跳过")
        
        # 提交更改
        conn.commit()
        
        # 验证更新后的表结构
        cursor.execute("PRAGMA table_info(game)")
        updated_columns = [column[1] for column in cursor.fetchall()]
        print(f"🔄 更新后字段: {updated_columns}")
        
        # 关闭连接
        conn.close()
        
        if added_columns:
            print(f"✅ 数据库模式更新完成！添加了 {len(added_columns)} 个字段：{added_columns}")
        else:
            print("ℹ️ 数据库模式已是最新，无需更新")
        
        return True
        
    except Exception as e:
        print(f"❌ 数据库更新失败: {e}")
        return False

def verify_schema():
    """验证数据库模式是否正确"""
    db_path = os.path.join(os.path.dirname(__file__), 'instance', 'gamestock.db')
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 检查所有必需的字段
        cursor.execute("PRAGMA table_info(game)")
        columns = [column[1] for column in cursor.fetchall()]
        
        required_columns = [
            'id', 'steam_id', 'name', 'name_zh', 'sales_count', 
            'positive_reviews', 'total_reviews', 'current_price',
            'last_updated', 'icon_url', 'header_image', 
            'data_accuracy', 'api_status'
        ]
        
        missing_columns = [col for col in required_columns if col not in columns]
        
        conn.close()
        
        if missing_columns:
            print(f"❌ 缺失字段: {missing_columns}")
            return False
        else:
            print("✅ 数据库模式验证通过，所有必需字段都存在")
            return True
            
    except Exception as e:
        print(f"❌ 模式验证失败: {e}")
        return False

if __name__ == '__main__':
    print("🚀 GameStock 数据库模式更新工具")
    print("=" * 50)
    
    # 更新数据库模式
    if update_database_schema():
        # 验证更新结果
        if verify_schema():
            print("\n🎉 数据库更新成功，现在可以正常启动应用了！")
            print("💡 使用命令: python run.py")
        else:
            print("\n❌ 数据库验证失败，请检查日志")
    else:
        print("\n❌ 数据库更新失败")
    
    print("=" * 50) 