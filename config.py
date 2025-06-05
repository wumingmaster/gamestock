import os
from datetime import timedelta

class Config:
    # 基本配置
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'gamestock-secret-key-development'
    
    # 数据库配置
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///gamestock.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Steam API配置
    STEAM_API_KEY = 'F7CA22D08BE8B62D94BA5568702B08B2'
    STEAM_API_BASE = 'https://api.steampowered.com'
    STEAM_STORE_BASE = 'https://store.steampowered.com'
    
    # 应用配置
    DEBUG = True
    TESTING = False
    
    # 游戏股价计算配置
    MIN_SALES_FOR_CALCULATION = 100  # 最小销量要求
    DEFAULT_REVIEW_RATE = 0.8  # 默认好评率
    
    # 用户初始资金
    INITIAL_USER_BALANCE = 10000.0

class DevelopmentConfig(Config):
    DEBUG = True
    
class ProductionConfig(Config):
    DEBUG = False
    SECRET_KEY = os.environ.get('SECRET_KEY')
    
class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///test_gamestock.db'

# 配置字典
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
} 