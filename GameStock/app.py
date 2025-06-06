from flask import Flask, jsonify, request, render_template, session
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os
from dotenv import load_dotenv
import math
import requests
from datetime import datetime
import hashlib
import secrets

# 加载环境变量
load_dotenv()

# 创建Flask应用
app = Flask(__name__)
CORS(app)

# 数据库配置
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////root/GameStock/instance/gamestock.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'gamestock-secret-key'

# 初始化数据库
db = SQLAlchemy(app)

# Steam API配置
STEAM_API_KEY = 'F7CA22D08BE8B62D94BA5568702B08B2'
STEAM_API_BASE = 'https://api.steampowered.com'

# 数据库模型
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    balance = db.Column(db.Float, default=1000.0)  # 初始资金改为1000（1万虚拟币）
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Steam游戏表模型
class Game(db.Model):
    id = db.Column(db.Integer, primary_key=True)           # 数据库自增ID
    appid = db.Column(db.Integer, unique=True, nullable=False)  # Steam官方AppID
    name = db.Column(db.String(200), nullable=False)       # 游戏名称
    icon_url = db.Column(db.String(300))                   # 游戏icon的URL
    price = db.Column(db.Float)                            # 当前价格
    currency = db.Column(db.String(10))                    # 货币类型（如CNY、USD）
    last_update = db.Column(db.DateTime)                   # 最后一次同步时间
    short_description = db.Column(db.String(500))          # 简短描述
    # 可扩展字段
    # genres = db.Column(db.String(200))                   # 类型标签
    # release_date = db.Column(db.String(50))              # 发售日期
    # developer = db.Column(db.String(100))                # 开发商
    # publisher = db.Column(db.String(100))                # 发行商 