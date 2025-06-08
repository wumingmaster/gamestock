import os
import subprocess
import sys
# 自动kill占用5001端口的进程，仅开发环境使用
try:
    result = subprocess.check_output("lsof -i:5001 | grep LISTEN", shell=True).decode()
    for line in result.strip().split('\n'):
        if not line:
            continue
        parts = line.split()
        pid = int(parts[1])
        print(f"[0608-1032] 自动kill占用端口5001的进程: PID={pid}")
        os.kill(pid, 9)
except Exception as e:
    print(f"[0608-1032] 端口5001未被占用或kill失败: {e}")

from flask import Flask, jsonify, request, render_template, session, send_file
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os
from dotenv import load_dotenv
import math
import requests
from datetime import datetime
import hashlib
import secrets
import logging

# 版本信息
APP_VERSION = '2025-06-08-1032-PORTFOLIO-FIX'
print(f'🚀 [app.py][0608-1032] 启动，版本号: {APP_VERSION}', file=sys.stderr)

# 加载环境变量
load_dotenv()

# 创建Flask应用
app = Flask(__name__)
CORS(app)

# 数据库配置
# 检测运行环境，自动选择数据库路径
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if os.path.exists('/root/GameStock/instance/gamestock.db'):
    # 服务器环境
    DB_PATH = 'sqlite:////root/GameStock/instance/gamestock.db'
    print(f'🗄️ [Database] 使用服务器数据库路径: {DB_PATH}', file=sys.stderr)
else:
    # 本地开发环境
    DB_PATH = 'sqlite:///gamestock.db'
    print(f'🗄️ [Database] 使用本地数据库路径: {DB_PATH}', file=sys.stderr)

app.config['SQLALCHEMY_DATABASE_URI'] = DB_PATH
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'gamestock-secret-key'

# 初始化数据库
db = SQLAlchemy(app)

# Steam API配置
STEAM_API_KEY = 'F7CA22D08BE8B62D94BA5568702B08B2'
STEAM_API_BASE = 'https://api.steampowered.com'

# 日志目录和文件配置
LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs')
LOG_FILE = os.path.join(LOG_DIR, 'app.log')
if not os.path.exists(LOG_DIR):
    os.makedirs(LOG_DIR)
# 强制为 root logger 添加 FileHandler，确保所有日志都写入文件
file_handler = logging.FileHandler(LOG_FILE, encoding='utf-8')
file_handler.setLevel(logging.INFO)
formatter = logging.Formatter('[%(asctime)s] %(levelname)s in %(module)s: %(message)s')
file_handler.setFormatter(formatter)
logging.getLogger().addHandler(file_handler)
logging.getLogger().setLevel(logging.INFO)
# 强制 Flask app.logger 也写入文件
try:
    app.logger.handlers = []
    app.logger.propagate = True
    app.logger.addHandler(file_handler)
except Exception as e:
    pass

# 数据库模型
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    balance = db.Column(db.Float, default=1000.0)  # 初始资金改为1000（1万虚拟币）
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    
    def set_password(self, password):
        """设置用户密码"""
        salt = secrets.token_hex(16)
        password_hash = hashlib.sha256((password + salt).encode()).hexdigest()
        self.password_hash = f"{salt}:{password_hash}"
    
    def check_password(self, password):
        """验证用户密码"""
        try:
            salt, stored_hash = self.password_hash.split(':')
            password_hash = hashlib.sha256((password + salt).encode()).hexdigest()
            return password_hash == stored_hash
        except:
            return False
    
    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'balance': self.balance,
            'created_at': self.created_at.isoformat(),
            'is_active': self.is_active
        }

class Game(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    steam_id = db.Column(db.String(20), unique=True, nullable=False)
    name = db.Column(db.String(200), nullable=False)  # 英文原名
    name_zh = db.Column(db.String(200))  # 中文名称
    sales_count = db.Column(db.Integer, default=0)
    positive_reviews = db.Column(db.Integer, default=0)
    total_reviews = db.Column(db.Integer, default=0)
    current_price = db.Column(db.Float, default=0.0)
    last_updated = db.Column(db.DateTime, default=datetime.utcnow)
    icon_url = db.Column(db.String(500))  # 游戏图标URL
    header_image = db.Column(db.String(500))  # 游戏头图URL
    data_accuracy = db.Column(db.String(20), default='unknown')  # 数据准确性指示器
    api_status = db.Column(db.String(50), default='not_checked')  # API状态
    
    @property
    def review_rate(self):
        if self.total_reviews == 0:
            return 0.0
        return self.positive_reviews / self.total_reviews
    
    def get_localized_name(self, language='en'):
        """获取本地化的游戏名称"""
        if language == 'zh' or language.startswith('zh'):
            return self.name_zh if self.name_zh else self.name
        return self.name
    
    @property
    def calculated_stock_price(self):
        if self.positive_reviews <= 0:
            return 0.0
        # 基于好评数的优化公式: (log10(好评数))^1.3 × (好评率)^0.5 × 20
        # 使用精确的好评数替代不准确的估算销量，避免好评率重复计算
        return (math.log10(self.positive_reviews) ** 1.3) * (self.review_rate ** 0.5) * 20
    
    def to_dict(self, language='en'):
        # 数据时效性检查
        from datetime import datetime, timedelta
        now = datetime.utcnow()
        data_age = now - self.last_updated
        is_stale = data_age > timedelta(hours=1)  # 1小时后数据被认为过时
        
        return {
            'id': self.id,
            'steam_id': self.steam_id,
            'name': self.get_localized_name(language),
            'name_original': self.name,
            'name_zh': self.name_zh,
            'icon_url': self.icon_url,
            'header_image': self.header_image,
            'sales_count': self.sales_count,
            'positive_reviews': self.positive_reviews,
            'total_reviews': self.total_reviews,
            'review_rate': self.review_rate,
            'current_price': self.calculated_stock_price,
            'last_updated': self.last_updated.isoformat(),
            'data_quality': {
                'accuracy': self.data_accuracy,
                'api_status': self.api_status,
                'is_realtime': not is_stale,
                'age_hours': round(data_age.total_seconds() / 3600, 1),
                'freshness': 'fresh' if not is_stale else 'stale',
                'source': 'Steam API' if self.data_accuracy == 'accurate' else 'Unknown'
            }
        }

class Portfolio(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    game_id = db.Column(db.Integer, db.ForeignKey('game.id'), nullable=False)
    shares = db.Column(db.Integer, nullable=False)
    avg_buy_price = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = db.relationship('User', backref=db.backref('portfolios', lazy=True))
    game = db.relationship('Game', backref=db.backref('portfolios', lazy=True))
    
    def to_dict(self):
        if not self.game:
            logging.error(f"[2029] [Portfolio.to_dict] game为None，game_id={self.game_id}, portfolio_id={self.id}")
            return None
        # 防止positive_reviews为None
        positive_reviews = self.game.positive_reviews if self.game.positive_reviews is not None else 0
        # 防止calculated_stock_price报错
        try:
            current_price = self.game.calculated_stock_price
        except Exception as e:
            logging.error(f"[2029] [Portfolio.to_dict] 计算current_price出错: {e}, game_id={self.game_id}, portfolio_id={self.id}")
            current_price = 0
        total_value = self.shares * current_price
        profit_loss = (current_price - self.avg_buy_price) * self.shares
        profit_loss_percent = (profit_loss / (self.avg_buy_price * self.shares)) * 100 if self.avg_buy_price > 0 else 0
        return {
            'id': self.id,
            'user_id': self.user_id,
            'game_id': self.game_id,
            'game_name': self.game.name,
            'game_steam_id': self.game.steam_id,
            'shares': self.shares,
            'avg_buy_price': self.avg_buy_price,
            'current_price': current_price,
            'total_value': total_value,
            'profit_loss': profit_loss,
            'profit_loss_percent': profit_loss_percent,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

class Transaction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    game_id = db.Column(db.Integer, db.ForeignKey('game.id'), nullable=False)
    transaction_type = db.Column(db.String(10), nullable=False)  # 'buy' or 'sell'
    shares = db.Column(db.Integer, nullable=False)
    price_per_share = db.Column(db.Float, nullable=False)
    total_amount = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User', backref=db.backref('transactions', lazy=True))
    game = db.relationship('Game', backref=db.backref('transactions', lazy=True))
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'game_id': self.game_id,
            'game_name': self.game.name,
            'game_steam_id': self.game.steam_id,
            'transaction_type': self.transaction_type,
            'shares': self.shares,
            'price_per_share': self.price_per_share,
            'total_amount': self.total_amount,
            'created_at': self.created_at.isoformat()
        }

class RechargeRecord(db.Model):
    """充值记录模型"""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    payment_amount = db.Column(db.Float, nullable=False)  # 实际支付金额（美元）
    virtual_funds = db.Column(db.Float, nullable=False)   # 获得的虚拟资金
    payment_method = db.Column(db.String(50), nullable=False)  # 支付方式
    transaction_id = db.Column(db.String(100), unique=True, nullable=False)  # 交易ID
    status = db.Column(db.String(20), nullable=False, default='pending')  # pending, completed, failed
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User', backref=db.backref('recharge_records', lazy=True))
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'payment_amount': self.payment_amount,
            'virtual_funds': self.virtual_funds,
            'payment_method': self.payment_method,
            'transaction_id': self.transaction_id,
            'status': self.status,
            'created_at': self.created_at.isoformat(),
            'exchange_rate': f"1 USD = {self.virtual_funds/self.payment_amount:,.0f} 虚拟资金" if self.payment_amount > 0 else "N/A"
        }

# Steam API 相关函数
def get_game_basic_info(steam_id):
    """从Steam API获取游戏基本信息（名称、图标等）- 改进版本"""
    try:
        # 获取英文游戏信息
        store_url_en = f"https://store.steampowered.com/api/appdetails?appids={steam_id}&l=english"
        # 获取中文游戏信息
        store_url_zh = f"https://store.steampowered.com/api/appdetails?appids={steam_id}&l=schinese"
        
        game_info = {}
        
        # 获取英文信息
        en_response = requests.get(store_url_en, timeout=10)
        if en_response.status_code == 200:
            en_data = en_response.json()
            if str(steam_id) in en_data and en_data[str(steam_id)].get('success'):
                en_game_data = en_data[str(steam_id)]['data']
                game_info['name'] = en_game_data.get('name', f'Game {steam_id}')
                
                # 多重图标URL策略 - 基于Steam CDN的多种尺寸
                capsule_url = f"https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/{steam_id}/capsule_231x87.jpg"
                library_url = f"https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/{steam_id}/library_600x900.jpg"
                icon_url = f"https://steamcdn-a.akamaihd.net/steamcommunity/public/images/apps/{steam_id}/{en_game_data.get('icon', steam_id)}.jpg" if en_game_data.get('icon') else capsule_url
                
                # 优先使用原生图标，后备使用胶囊图
                game_info['icon_url'] = icon_url
                game_info['capsule_url'] = capsule_url  # 额外提供胶囊图作为后备
                game_info['library_url'] = library_url  # 提供库存图作为后备
                game_info['header_image'] = en_game_data.get('header_image', f"https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/{steam_id}/header.jpg")
        
        # 获取中文信息
        zh_response = requests.get(store_url_zh, timeout=10)
        if zh_response.status_code == 200:
            zh_data = zh_response.json()
            if str(steam_id) in zh_data and zh_data[str(steam_id)].get('success'):
                zh_game_data = zh_data[str(steam_id)]['data']
                game_info['name_zh'] = zh_game_data.get('name')
        
        return game_info
        
    except Exception as e:
        print(f"⚠️ 获取游戏基本信息失败: {e}")
        # 提供多种后备图标URL
        capsule_url = f"https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/{steam_id}/capsule_231x87.jpg"
        return {
            'name': f'Game {steam_id}',
            'name_zh': None,
            'icon_url': capsule_url,
            'capsule_url': capsule_url,
            'library_url': f"https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/{steam_id}/library_600x900.jpg",
            'header_image': f"https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/{steam_id}/header.jpg"
        }

def get_game_details(steam_id):
    """从Steam API获取游戏详情 - 增强版本"""
    try:
        print(f"🔍 正在获取Steam ID: {steam_id} 的数据...")
        
        # 获取游戏评论数据 - 使用完整参数获取所有评论数据
        reviews_url = f"https://store.steampowered.com/appreviews/{steam_id}?json=1&language=all&review_type=all&purchase_type=all&num_per_page=0"
        
        reviews_response = requests.get(reviews_url, timeout=10)
        
        if reviews_response.status_code != 200:
            print(f"❌ Steam API请求失败，状态码: {reviews_response.status_code}")
            return {
                'error': f'Steam API请求失败 (状态码: {reviews_response.status_code})',
                'positive_reviews': 0,
                'total_reviews': 0,
                'sales_estimate': 0,
                'data_accuracy': 'unavailable'
            }
        
        reviews_data = reviews_response.json()
        
        if reviews_data.get('success') != 1:
            print(f"❌ Steam API返回失败: {reviews_data}")
            return {
                'error': 'Steam API返回数据失败，可能是无效的Steam ID',
                'positive_reviews': 0,
                'total_reviews': 0,
                'sales_estimate': 0,
                'data_accuracy': 'unavailable'
            }
        
        query_summary = reviews_data.get('query_summary', {})
        positive_reviews = query_summary.get('total_positive', 0)
        total_reviews = query_summary.get('total_reviews', 0)
        
        # 如果没有评论数据，标记为无法获取
        if total_reviews == 0:
            print(f"⚠️ 游戏 {steam_id} 暂无评论数据")
            return {
                'error': '该游戏暂无评论数据，无法计算股价',
                'positive_reviews': 0,
                'total_reviews': 0,
                'sales_estimate': 0,
                'data_accuracy': 'no_reviews'
            }
        
        # 估算销量（说明这是估算值）
        sales_estimate = total_reviews * 25  # 使用25倍系数
        
        # 获取游戏基本信息（名称、图标等）
        basic_info = get_game_basic_info(steam_id)
        
        print(f"✅ 成功获取数据:")
        print(f"   游戏名称: {basic_info.get('name', 'N/A')} / {basic_info.get('name_zh', '暂无中文名')}")
        print(f"   好评数: {positive_reviews:,} (精确)")
        print(f"   总评论数: {total_reviews:,} (精确)")
        print(f"   估算销量: {sales_estimate:,} (估算值，±50%误差)")
        print(f"   好评率: {(positive_reviews/total_reviews)*100:.1f}%")
        print(f"   图标URL: {basic_info.get('icon_url', 'N/A')}")
        
        result = {
            'positive_reviews': positive_reviews,
            'total_reviews': total_reviews,
            'sales_estimate': sales_estimate,
            'data_accuracy': 'accurate',
            'notes': '好评数和总评论数为Steam API精确数据，销量为估算值'
        }
        
        # 合并基本信息
        result.update(basic_info)
        
        return result
        
    except requests.exceptions.Timeout:
        print(f"❌ Steam API请求超时")
        return {
            'error': 'Steam API请求超时，请稍后重试',
            'positive_reviews': 0,
            'total_reviews': 0,
            'sales_estimate': 0,
            'data_accuracy': 'timeout'
        }
    except requests.exceptions.RequestException as e:
        print(f"❌ 网络请求错误: {e}")
        return {
            'error': f'网络请求失败: {str(e)}',
            'positive_reviews': 0,
            'total_reviews': 0,
            'sales_estimate': 0,
            'data_accuracy': 'network_error'
        }
    except Exception as e:
        print(f"❌ 获取游戏数据时发生未知错误: {e}")
        return {
            'error': f'数据获取失败: {str(e)}',
            'positive_reviews': 0,
            'total_reviews': 0,
            'sales_estimate': 0,
            'data_accuracy': 'error'
        }

# 辅助函数
def get_current_user():
    """获取当前登录用户"""
    user_id = session.get('user_id')
    if user_id:
        return User.query.get(user_id)
    return None

def login_required(f):
    """登录验证装饰器"""
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': '请先登录'}), 401
        return f(*args, **kwargs)
    return decorated_function

# API 路由
@app.route('/')
def home():
    return render_template('index.html')

@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html')

@app.route('/api')
def api_info():
    return jsonify({
        'message': 'GameStock API - Steam游戏股票交易模拟器',
        'version': '2.1.0',
        'new_features': [
            '增强Steam API数据获取准确性',
            '详细的错误信息和数据质量指示',
            '付费充值系统（$4.99 = $100,000虚拟资金）'
        ],
        'endpoints': {
            'auth': {
                'register': 'POST /api/auth/register',
                'login': 'POST /api/auth/login',
                'logout': 'POST /api/auth/logout',
                'profile': 'GET /api/auth/profile'
            },
            'payment': {
                'recharge': 'POST /api/payment/recharge',
                'history': 'GET /api/payment/history'
            },
            'games': {
                'list': 'GET /api/games',
                'add': 'POST /api/games',
                'update': 'POST /api/games/{id}/update'
            },
            'trading': {
                'buy': 'POST /api/trading/buy',
                'sell': 'POST /api/trading/sell',
                'portfolio': 'GET /api/trading/portfolio',
                'transactions': 'GET /api/trading/transactions'
            }
        }
    })

# 用户认证相关API
@app.route('/api/auth/register', methods=['POST'])
def register():
    """用户注册"""
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    
    if not username or not email or not password:
        return jsonify({'error': '用户名、邮箱和密码都是必填项'}), 400
    
    if len(password) < 6:
        return jsonify({'error': '密码长度至少6位'}), 400
    
    # 检查用户是否已存在
    existing_user = User.query.filter((User.username == username) | (User.email == email)).first()
    if existing_user:
        return jsonify({'error': '用户名或邮箱已存在'}), 400
    
    # 创建新用户
    new_user = User(username=username, email=email)
    new_user.set_password(password)
    
    db.session.add(new_user)
    db.session.commit()
    
    # 自动登录
    session['user_id'] = new_user.id
    
    return jsonify({
        'message': '注册成功',
        'user': new_user.to_dict()
    }), 201

@app.route('/api/auth/login', methods=['POST'])
def login():
    logging.info("[1848] [Login API] 进入 login 路由")
    data = request.get_json()
    username = data.get('username')
    logging.info(f"[1846] [Login API] 登录请求: username={username}")
    password = data.get('password')
    
    if not username or not password:
        return jsonify({'error': '用户名和密码都是必填项'}), 400
    
    # 查找用户（支持用户名或邮箱登录）
    user = User.query.filter((User.username == username) | (User.email == username)).first()
    
    if not user or not user.check_password(password):
        return jsonify({'error': '用户名或密码错误'}), 401
    
    if not user.is_active:
        return jsonify({'error': '账户已被禁用'}), 401
    
    # 设置会话
    session['user_id'] = user.id
    
    logging.info(f"[1846] [Login API] 登录成功: user_id={user.id}, username={user.username}")
    return jsonify({
        'message': '登录成功',
        'user': user.to_dict()
    })

@app.route('/api/auth/logout', methods=['POST'])
def logout():
    """用户退出登录"""
    session.pop('user_id', None)
    return jsonify({'message': '退出登录成功'})

@app.route('/api/auth/profile', methods=['GET'])
@login_required
def get_profile():
    """获取用户资料"""
    user = get_current_user()
    return jsonify(user.to_dict())

@app.route('/api/auth/profile', methods=['PUT'])
@login_required
def update_profile():
    """更新用户资料"""
    user = get_current_user()
    data = request.get_json()
    
    if 'email' in data:
        # 检查邮箱是否已被使用
        existing_user = User.query.filter(User.email == data['email'], User.id != user.id).first()
        if existing_user:
            return jsonify({'error': '邮箱已被使用'}), 400
        user.email = data['email']
    
    if 'password' in data and data['password']:
        if len(data['password']) < 6:
            return jsonify({'error': '密码长度至少6位'}), 400
        user.set_password(data['password'])
    
    db.session.commit()
    return jsonify({
        'message': '资料更新成功',
        'user': user.to_dict()
    })

# 充值相关API
@app.route('/api/payment/recharge', methods=['POST'])
@login_required
def recharge_account():
    """用户账户充值"""
    user = get_current_user()
    data = request.get_json()
    
    amount = data.get('amount')
    payment_method = data.get('payment_method', 'credit_card')
    
    # 验证充值金额
    valid_amounts = [4.99]  # 目前只支持$4.99充值
    if amount not in valid_amounts:
        return jsonify({
            'error': '无效的充值金额',
            'valid_amounts': valid_amounts,
            'message': '目前只支持$4.99充值获得$100,000虚拟资金'
        }), 400
    
    # 计算虚拟资金 ($4.99 = $100,000虚拟币，汇率约1:20040)
    virtual_funds = 100000.0 if amount == 4.99 else 0
    
    if virtual_funds == 0:
        return jsonify({'error': '充值金额配置错误'}), 400
    
    # 模拟支付处理
    # 在实际应用中，这里会调用支付网关API
    payment_result = simulate_payment_processing(amount, payment_method)
    
    if payment_result['success']:
        # 支付成功，增加用户余额
        old_balance = user.balance
        user.balance += virtual_funds
        
        # 记录充值交易
        recharge_record = RechargeRecord(
            user_id=user.id,
            payment_amount=amount,
            virtual_funds=virtual_funds,
            payment_method=payment_method,
            transaction_id=payment_result['transaction_id'],
            status='completed'
        )
        
        db.session.add(recharge_record)
        db.session.commit()
        
        return jsonify({
            'message': '充值成功！',
            'payment_details': {
                'amount_paid': f"${amount:.2f}",
                'virtual_funds_received': f"${virtual_funds:,.2f}",
                'exchange_rate': f"1 USD = {virtual_funds/amount:,.0f} 虚拟资金"
            },
            'account_update': {
                'old_balance': f"${old_balance:,.2f}",
                'new_balance': f"${user.balance:,.2f}",
                'increase': f"${virtual_funds:,.2f}"
            },
            'transaction_id': payment_result['transaction_id'],
            'user': user.to_dict()
        })
    else:
        return jsonify({
            'error': '支付失败',
            'message': payment_result.get('error', '支付处理失败'),
            'details': payment_result
        }), 400

@app.route('/api/payment/history', methods=['GET'])
@login_required
def get_recharge_history():
    """获取用户充值历史"""
    user = get_current_user()
    
    records = RechargeRecord.query.filter_by(user_id=user.id).order_by(RechargeRecord.created_at.desc()).all()
    
    return jsonify({
        'recharge_history': [record.to_dict() for record in records],
        'total_recharged': sum(record.payment_amount for record in records if record.status == 'completed'),
        'total_virtual_funds': sum(record.virtual_funds for record in records if record.status == 'completed')
    })

def simulate_payment_processing(amount, payment_method):
    """模拟支付处理 - 实际应用中应该集成真实的支付网关"""
    import uuid
    import random
    
    # 模拟处理时间
    success_rate = 0.95  # 95%成功率
    
    if random.random() < success_rate:
        return {
            'success': True,
            'transaction_id': f"TXN_{uuid.uuid4().hex[:12].upper()}",
            'payment_method': payment_method,
            'amount': amount,
            'currency': 'USD',
            'status': 'completed',
            'message': '支付成功处理'
        }
    else:
        return {
            'success': False,
            'error': '支付网关暂时不可用，请稍后重试',
            'status': 'failed'
        }

# 游戏相关API
# 移除原有的 /api/games 端点 - 优化版本不需要返回所有游戏

@app.route('/api/games/<int:game_id>', methods=['GET'])
def get_game_detail(game_id):
    """获取单个游戏的详细信息 - 核心API"""
    try:
        game = Game.query.get(game_id)
        if not game:
            return jsonify({'error': '游戏不存在'}), 404
        
        accept_language = request.headers.get('Accept-Language', 'en')
        language = 'zh' if 'zh' in accept_language.lower() else 'en'
        
        return jsonify({
            'game': game.to_dict(language)
        })
        
    except Exception as e:
        print(f"Error in get_game_detail: {e}")
        return jsonify({'error': '获取游戏信息失败'}), 500

@app.route('/api/games', methods=['POST'])
def add_game():
    """添加新游戏 - 增强版本"""
    data = request.get_json()
    steam_id = data.get('steam_id')
    name = data.get('name')
    
    if not steam_id or not name:
        return jsonify({'error': '缺少必要参数：steam_id 和 name'}), 400
    
    # 检查游戏是否已存在
    existing_game = Game.query.filter_by(steam_id=steam_id).first()
    if existing_game:
        return jsonify({'error': f'游戏已存在：{existing_game.name}'}), 400
    
    # 从Steam API获取游戏数据
    game_details = get_game_details(steam_id)
    
    # 检查数据获取是否成功
    if game_details and game_details.get('error'):
        # 数据获取失败，但仍然创建游戏记录，使用默认值
        return jsonify({
            'error': game_details['error'],
            'data_accuracy': game_details.get('data_accuracy', 'error'),
            'message': '数据获取失败，无法创建游戏记录。请检查Steam ID是否正确，或稍后重试。',
            'suggested_actions': [
                '1. 验证Steam ID是否正确',
                '2. 检查该游戏是否有足够的评论数据',
                '3. 稍后重试（可能是网络问题）'
            ]
        }), 400
    
    # 数据获取成功，创建游戏记录
    if game_details and game_details.get('data_accuracy') == 'accurate':
        new_game = Game(
            steam_id=steam_id,
            name=game_details.get('name', name),  # 使用从Steam API获取的英文名称
            name_zh=game_details.get('name_zh'),  # 中文名称
            sales_count=game_details.get('sales_estimate', 1000),
            positive_reviews=game_details.get('positive_reviews', 800),
            total_reviews=game_details.get('total_reviews', 1000),
            icon_url=game_details.get('icon_url'),  # 游戏图标
            header_image=game_details.get('header_image'),  # 游戏头图
            data_accuracy='accurate',
            api_status='success'
        )
        
        db.session.add(new_game)
        db.session.commit()
        
        game_dict = new_game.to_dict()
        game_dict['data_quality'] = {
            'accuracy': 'high',
            'source': 'Steam API',
            'notes': game_details.get('notes', ''),
            'last_updated': new_game.last_updated.isoformat()
        }
        
        return jsonify({
            'message': f'成功添加游戏：{name}',
            'game': game_dict
        }), 201
    
    # 如果没有获取到数据，返回错误
    return jsonify({
        'error': '无法获取游戏数据',
        'message': '请检查Steam ID是否正确，或稍后重试'
    }), 400

@app.route('/api/games/<int:game_id>/update', methods=['POST'])
def update_game_data(game_id):
    """更新游戏数据 - 增强版本"""
    game = Game.query.get_or_404(game_id)
    
    # 从Steam API获取最新数据
    game_details = get_game_details(game.steam_id)
    
    # 检查数据获取结果
    if game_details and game_details.get('error'):
        return jsonify({
            'error': game_details['error'],
            'data_accuracy': game_details.get('data_accuracy', 'error'),
            'message': f'无法更新游戏 "{game.name}" 的数据',
            'game_id': game_id,
            'steam_id': game.steam_id,
            'suggested_actions': [
                '稍后重试更新',
                '检查网络连接',
                '验证Steam ID是否仍然有效'
            ]
        }), 400
    
    # 数据获取成功，更新游戏记录
    if game_details and game_details.get('data_accuracy') == 'accurate':
        old_data = {
            'positive_reviews': game.positive_reviews,
            'total_reviews': game.total_reviews,
            'sales_count': game.sales_count,
            'price': game.calculated_stock_price
        }
        
        game.sales_count = game_details.get('sales_estimate', game.sales_count)
        game.positive_reviews = game_details.get('positive_reviews', game.positive_reviews)
        game.total_reviews = game_details.get('total_reviews', game.total_reviews)
        game.last_updated = datetime.utcnow()
        game.data_accuracy = 'accurate'
        game.api_status = 'success'
        
        db.session.commit()
        
        new_data = {
            'positive_reviews': game.positive_reviews,
            'total_reviews': game.total_reviews,
            'sales_count': game.sales_count,
            'price': game.calculated_stock_price
        }
        
        # 计算变化
        changes = {}
        for key in old_data:
            old_val = old_data[key]
            new_val = new_data[key]
            if old_val != new_val:
                if key == 'price':
                    change_percent = ((new_val - old_val) / old_val * 100) if old_val > 0 else 0
                    changes[key] = {
                        'old': f"${old_val:.2f}",
                        'new': f"${new_val:.2f}",
                        'change': f"{change_percent:+.1f}%"
                    }
                else:
                    changes[key] = {
                        'old': old_val,
                        'new': new_val,
                        'change': new_val - old_val
                    }
        
        game_dict = game.to_dict()
        game_dict['update_info'] = {
            'changes': changes,
            'data_quality': {
                'accuracy': 'high',
                'source': 'Steam API',
                'notes': game_details.get('notes', ''),
                'updated_at': game.last_updated.isoformat()
            }
        }
        
        return jsonify({
            'message': f'成功更新游戏 "{game.name}" 的数据',
            'game': game_dict
        })
    
    return jsonify({
        'error': '数据获取失败',
        'message': f'无法获取游戏 "{game.name}" 的最新数据'
    }), 500

@app.route('/api/games/refresh-all', methods=['POST'])
def refresh_all_games():
    """刷新所有游戏的Steam数据"""
    games = Game.query.all()
    results = []
    
    for game in games:
        try:
            # 获取最新Steam数据
            game_details = get_game_details(game.steam_id)
            
            if game_details and game_details.get('data_accuracy') == 'accurate':
                # 更新游戏数据
                old_price = game.calculated_stock_price
                
                # 更新基本信息
                if game_details.get('name'):
                    game.name = game_details.get('name')
                if game_details.get('name_zh'):
                    game.name_zh = game_details.get('name_zh')
                if game_details.get('icon_url'):
                    game.icon_url = game_details.get('icon_url')
                if game_details.get('header_image'):
                    game.header_image = game_details.get('header_image')
                
                # 更新评论和销量数据
                game.positive_reviews = game_details.get('positive_reviews', game.positive_reviews)
                game.total_reviews = game_details.get('total_reviews', game.total_reviews)
                game.sales_count = game_details.get('sales_estimate', game.sales_count)
                game.last_updated = datetime.utcnow()
                game.data_accuracy = 'accurate'
                game.api_status = 'success'
                
                new_price = game.calculated_stock_price
                price_change = ((new_price - old_price) / old_price * 100) if old_price > 0 else 0
                
                results.append({
                    'game_name': game.name,
                    'steam_id': game.steam_id,
                    'status': 'updated',
                    'old_price': f"${old_price:.2f}",
                    'new_price': f"${new_price:.2f}",
                    'price_change': f"{price_change:+.1f}%",
                    'positive_reviews': game.positive_reviews,
                    'total_reviews': game.total_reviews
                })
            else:
                # 数据获取失败
                game.data_accuracy = 'error'
                game.api_status = game_details.get('data_accuracy', 'error') if game_details else 'network_error'
                
                results.append({
                    'game_name': game.name,
                    'steam_id': game.steam_id,
                    'status': 'failed',
                    'error': game_details.get('error', '网络错误') if game_details else '网络错误'
                })
                
        except Exception as e:
            results.append({
                'game_name': game.name,
                'steam_id': game.steam_id,
                'status': 'error',
                'error': str(e)
            })
    
    db.session.commit()
    
    successful_updates = len([r for r in results if r['status'] == 'updated'])
    failed_updates = len([r for r in results if r['status'] in ['failed', 'error']])
    
    return jsonify({
        'message': f'数据刷新完成：{successful_updates}个成功，{failed_updates}个失败',
        'summary': {
            'total_games': len(games),
            'successful_updates': successful_updates,
            'failed_updates': failed_updates,
            'success_rate': f"{(successful_updates/len(games)*100) if games else 0:.1f}%"
        },
        'details': results,
        'refresh_timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/games/search', methods=['GET'])
def search_games():
    keyword = request.args.get('keyword', '').strip()
    if not keyword:
        return jsonify([])
    # 支持中英文名模糊匹配
    games = Game.query.filter(
        (Game.name.ilike(f'%{keyword}%')) | (Game.name_zh.ilike(f'%{keyword}%'))
    ).limit(50).all()
    return jsonify([g.to_dict(language='zh') for g in games])

# 交易相关API
@app.route('/api/trading/buy', methods=['POST'])
@login_required
def buy_stock():
    """买入股票"""
    try:
        user = get_current_user()
        data = request.get_json()
        logging.info(f"[1846] [Buy API] 用户 {user.id} 买入请求: {data}")
        game_id = data.get('game_id')
        shares = data.get('shares')
        
        if not game_id or not shares:
            return jsonify({'error': '缺少必要参数'}), 400
        
        if shares <= 0:
            return jsonify({'error': '股数必须大于0'}), 400
        
        # 获取游戏信息
        game = Game.query.get(game_id)
        if not game:
            return jsonify({'error': '游戏不存在'}), 404
        
        current_price = game.calculated_stock_price
        total_cost = current_price * shares
        
        # 检查用户余额
        if user.balance < total_cost:
            return jsonify({'error': f'余额不足，需要${total_cost:.2f}，当前余额${user.balance:.2f}'}), 400
        
        # 扣除资金
        user.balance -= total_cost
        
        # 更新或创建投资组合记录
        portfolio = Portfolio.query.filter_by(user_id=user.id, game_id=game_id).first()
        
        if portfolio:
            # 计算新的平均买入价格
            total_shares = portfolio.shares + shares
            total_cost_old = portfolio.shares * portfolio.avg_buy_price
            new_avg_price = (total_cost_old + total_cost) / total_shares
            
            portfolio.shares = total_shares
            portfolio.avg_buy_price = new_avg_price
            portfolio.updated_at = datetime.utcnow()
        else:
            # 创建新的投资组合记录
            portfolio = Portfolio(
                user_id=user.id,
                game_id=game_id,
                shares=shares,
                avg_buy_price=current_price
            )
            db.session.add(portfolio)
        
        # 记录交易
        transaction = Transaction(
            user_id=user.id,
            game_id=game_id,
            transaction_type='buy',
            shares=shares,
            price_per_share=current_price,
            total_amount=total_cost
        )
        db.session.add(transaction)
        
        db.session.commit()
        
        logging.info(f"[1846] [Buy API] 买入成功: {result}")
        return jsonify({
            'message': f'成功买入{shares}股{game.name}',
            'transaction': transaction.to_dict(),
            'user_balance': user.balance,
            'portfolio': portfolio.to_dict()
        })
    except Exception as e:
        logging.error(f"[1846] [Buy API] 错误: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': '买入失败', 'message': str(e)}), 500

@app.route('/api/trading/sell', methods=['POST'])
@login_required
def sell_stock():
    """卖出股票"""
    try:
        user = get_current_user()
        data = request.get_json()
        logging.info(f"[1846] [Sell API] 用户 {user.id} 卖出请求: {data}")
        game_id = data.get('game_id')
        shares = data.get('shares')
        
        if not game_id or not shares:
            return jsonify({'error': '缺少必要参数'}), 400
        
        if shares <= 0:
            return jsonify({'error': '股数必须大于0'}), 400
        
        # 获取游戏信息
        game = Game.query.get(game_id)
        if not game:
            return jsonify({'error': '游戏不存在'}), 404
        
        # 获取用户持股
        portfolio = Portfolio.query.filter_by(user_id=user.id, game_id=game_id).first()
        if not portfolio:
            return jsonify({'error': '您没有持有该股票'}), 400
        
        if portfolio.shares < shares:
            return jsonify({'error': f'持股不足，您只有{portfolio.shares}股'}), 400
        
        current_price = game.calculated_stock_price
        total_revenue = current_price * shares
        
        # 增加资金
        user.balance += total_revenue
        
        # 更新投资组合
        portfolio.shares -= shares
        portfolio.updated_at = datetime.utcnow()
        
        # 如果卖完了就删除记录
        if portfolio.shares == 0:
            db.session.delete(portfolio)
            portfolio_result = None
        else:
            portfolio_result = portfolio.to_dict()
        
        # 记录交易
        transaction = Transaction(
            user_id=user.id,
            game_id=game_id,
            transaction_type='sell',
            shares=shares,
            price_per_share=current_price,
            total_amount=total_revenue
        )
        db.session.add(transaction)
        
        db.session.commit()
        
        logging.info(f"[1846] [Sell API] 卖出成功: {result}")
        return jsonify({
            'message': f'成功卖出{shares}股{game.name}',
            'transaction': transaction.to_dict(),
            'user_balance': user.balance,
            'portfolio': portfolio_result
        })
    except Exception as e:
        logging.error(f"[1846] [Sell API] 错误: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': '卖出失败', 'message': str(e)}), 500

@app.route('/api/trading/portfolio', methods=['GET'])
@login_required
def get_portfolio():
    logging.info("[1848] [Portfolio API] 进入 portfolio 路由")
    try:
        user = get_current_user()
        logging.info(f"[1846] [Portfolio API] 用户 {user.id} 请求投资组合")
        portfolios = Portfolio.query.filter_by(user_id=user.id).all()
        logging.info(f"[1846] [Portfolio API] 查到 {len(portfolios)} 条持仓")
        
        portfolio_data = []
        for p in portfolios:
            try:
                portfolio_dict = p.to_dict()
                portfolio_data.append(portfolio_dict)
                logging.info(f"[1846] [Portfolio API] 成功处理投资组合 ID {p.id}: {p.game.name}")
            except Exception as e:
                logging.error(f"[1846] [Portfolio API] 处理投资组合 ID {p.id} 时出错: {str(e)}")
                # 继续处理其他记录，不因为单个记录错误而中断
                continue
        
        # 计算总投资价值和盈亏
        total_value = sum(p.get('total_value', 0) for p in portfolio_data)
        total_cost = sum(p.get('avg_buy_price', 0) * p.get('shares', 0) for p in portfolio_data)
        total_profit_loss = total_value - total_cost
        total_profit_loss_percent = (total_profit_loss / total_cost * 100) if total_cost > 0 else 0
        
        result = {
            'success': True,
            'portfolios': portfolio_data,
            'summary': {
                'total_stocks': len(portfolio_data),
                'total_value': total_value,
                'total_cost': total_cost,
                'total_profit_loss': total_profit_loss,
                'total_profit_loss_percent': total_profit_loss_percent,
                'cash_balance': user.balance,
                'total_assets': total_value + user.balance
            }
        }
        
        logging.info(f"[1846] [Portfolio API] 返回数据: {result}")
        return jsonify(result)
        
    except Exception as e:
        logging.error(f"[1846] [Portfolio API] 错误: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return jsonify({
            'success': False,
            'error': 'Failed to fetch portfolio',
            'message': '获取投资组合失败',
            'debug_info': str(e)
        }), 500

@app.route('/api/trading/transactions', methods=['GET'])
@login_required
def get_transactions():
    """获取用户交易历史"""
    user = get_current_user()
    
    # 分页参数
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    # 查询交易记录
    transactions = Transaction.query.filter_by(user_id=user.id)\
        .order_by(Transaction.created_at.desc())\
        .paginate(page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'transactions': [t.to_dict() for t in transactions.items],
        'pagination': {
            'page': page,
            'per_page': per_page,
            'total': transactions.total,
            'pages': transactions.pages
        }
    })

# 原有的用户相关API（保持兼容性）
@app.route('/api/users', methods=['POST'])
def create_user():
    """创建新用户（简化版，不推荐使用）"""
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    
    if not username or not email:
        return jsonify({'error': '缺少必要参数'}), 400
    
    # 检查用户是否已存在
    existing_user = User.query.filter((User.username == username) | (User.email == email)).first()
    if existing_user:
        return jsonify({'error': '用户名或邮箱已存在'}), 400
    
    new_user = User(username=username, email=email)
    new_user.set_password('123456')  # 默认密码
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify(new_user.to_dict()), 201

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """获取用户信息"""
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict())

@app.route('/api/debug/logs', methods=['GET'])
def get_logs():
    """获取服务器日志文件内容，开发调试临时放开限制"""
    # 临时放开限制，允许任何IP访问
    log_path = LOG_FILE
    lines = int(request.args.get('lines', 500))
    if not os.path.exists(log_path):
        return jsonify({'error': '日志文件不存在'}), 404
    with open(log_path, 'r', encoding='utf-8') as f:
        all_lines = f.readlines()
        last_lines = all_lines[-lines:] if len(all_lines) > lines else all_lines
        return jsonify({'lines': last_lines})

@app.route('/api/debug/logfile', methods=['GET'])
def download_logfile():
    # 临时放开限制，允许任何IP访问
    log_path = LOG_FILE
    if not os.path.exists(log_path):
        return jsonify({'error': '日志文件不存在'}), 404
    return send_file(log_path, as_attachment=True)

# 初始化数据库
def init_db():
    """初始化数据库和测试数据"""
    db.create_all()
    
    # 添加一些测试游戏数据
    if Game.query.count() == 0:
        test_games = [
            {'steam_id': '730', 'name': 'Counter-Strike 2', 'sales': 50000000, 'positive': 400000, 'total': 500000},
            {'steam_id': '440', 'name': 'Team Fortress 2', 'sales': 30000000, 'positive': 300000, 'total': 350000},
            {'steam_id': '570', 'name': 'Dota 2', 'sales': 40000000, 'positive': 350000, 'total': 400000},
        ]
        
        for game_data in test_games:
            game = Game(
                steam_id=game_data['steam_id'],
                name=game_data['name'],
                sales_count=game_data['sales'],
                positive_reviews=game_data['positive'],
                total_reviews=game_data['total']
            )
            db.session.add(game)
        
        db.session.commit()

if __name__ == '__main__':
    with app.app_context():
        init_db()
    logging.info("Flask 服务已启动，日志测试 info [1846]")
    logging.warning("Flask 服务已启动，日志测试 warning [1846]")
    logging.error("Flask 服务已启动，日志测试 error [1846]")
    app.run(host='0.0.0.0', port=5001, debug=False) 