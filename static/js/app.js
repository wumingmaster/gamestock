// GameStock 前端应用脚本

class GameStockApp {
    constructor() {
        this.apiBase = '';
        this.games = [];
        this.currentUser = null;
        this.portfolio = null;
        this.init();
    }

    init() {
        console.log('🚀 初始化 GameStock 应用 v2.0');
        this.bindEvents();
        this.checkUserSession();
        this.loadGames();
    }

    bindEvents() {
        // 添加游戏表单提交
        document.getElementById('add-game-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.addGame();
        });

        // 交易股数变化计算总价
        const sharesInput = document.getElementById('trading-shares');
        if (sharesInput) {
            sharesInput.addEventListener('input', () => {
                this.updateTradingTotal();
            });
        }
    }

    // 用户认证相关方法
    async checkUserSession() {
        try {
            const response = await fetch('/api/auth/profile');
            if (response.ok) {
                this.currentUser = await response.json();
                this.updateUserInterface();
            } else {
                this.updateUserInterface();
            }
        } catch (error) {
            console.log('用户未登录');
            this.updateUserInterface();
        }
    }

    updateUserInterface() {
        const authSection = document.getElementById('auth-section');
        const userSection = document.getElementById('user-section');
        const loginPrompt = document.getElementById('login-prompt');

        if (this.currentUser) {
            // 已登录状态
            authSection.classList.add('d-none');
            userSection.classList.remove('d-none');
            loginPrompt.classList.add('d-none');
            
            document.getElementById('user-name').textContent = this.currentUser.username;
            document.getElementById('user-balance').textContent = this.currentUser.balance.toFixed(2);
        } else {
            // 未登录状态
            authSection.classList.remove('d-none');
            userSection.classList.add('d-none');
            loginPrompt.classList.remove('d-none');
        }
    }

    showLoginModal() {
        const modal = new bootstrap.Modal(document.getElementById('loginModal'));
        modal.show();
    }

    showRegisterModal() {
        const modal = new bootstrap.Modal(document.getElementById('registerModal'));
        modal.show();
    }

    async submitLogin() {
        const username = document.getElementById('login-username').value.trim();
        const password = document.getElementById('login-password').value;

        if (!username || !password) {
            this.showNotification('请填写完整的登录信息', 'error');
            return;
        }

        try {
            const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    username: username,
                    password: password
                })
            });

            const data = await response.json();

            if (response.ok) {
                this.currentUser = data.user;
                this.updateUserInterface();
                this.showNotification(data.message, 'success');
                
                // 关闭模态框
                const modal = bootstrap.Modal.getInstance(document.getElementById('loginModal'));
                modal.hide();
                
                // 清空表单
                document.getElementById('login-form').reset();
            } else {
                this.showNotification(data.error, 'error');
            }
        } catch (error) {
            console.error('登录失败:', error);
            this.showNotification('登录失败: ' + error.message, 'error');
        }
    }

    async submitRegister() {
        const username = document.getElementById('register-username').value.trim();
        const email = document.getElementById('register-email').value.trim();
        const password = document.getElementById('register-password').value;
        const confirm = document.getElementById('register-confirm').value;

        if (!username || !email || !password || !confirm) {
            this.showNotification('请填写完整的注册信息', 'error');
            return;
        }

        if (password !== confirm) {
            this.showNotification('两次输入的密码不一致', 'error');
            return;
        }

        if (password.length < 6) {
            this.showNotification('密码长度至少6位', 'error');
            return;
        }

        try {
            const response = await fetch('/api/auth/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    username: username,
                    email: email,
                    password: password
                })
            });

            const data = await response.json();

            if (response.ok) {
                this.currentUser = data.user;
                this.updateUserInterface();
                this.showNotification(data.message, 'success');
                
                // 关闭模态框
                const modal = bootstrap.Modal.getInstance(document.getElementById('registerModal'));
                modal.hide();
                
                // 清空表单
                document.getElementById('register-form').reset();
            } else {
                this.showNotification(data.error, 'error');
            }
        } catch (error) {
            console.error('注册失败:', error);
            this.showNotification('注册失败: ' + error.message, 'error');
        }
    }

    async logout() {
        try {
            const response = await fetch('/api/auth/logout', {
                method: 'POST'
            });

            if (response.ok) {
                this.currentUser = null;
                this.updateUserInterface();
                this.showNotification('退出登录成功', 'success');
            }
        } catch (error) {
            console.error('退出登录失败:', error);
            this.showNotification('退出登录失败: ' + error.message, 'error');
        }
    }

    // 游戏数据相关方法
    async loadGames() {
        console.log('📊 加载游戏数据...');
        try {
            const response = await fetch('/api/games');
            if (response.ok) {
                this.games = await response.json();
                this.renderGames();
                this.updateStatistics();
            } else {
                throw new Error('无法加载游戏数据');
            }
        } catch (error) {
            console.error('加载游戏数据失败:', error);
            this.showNotification('加载数据失败: ' + error.message, 'error');
        }
    }

    renderGames() {
        const tbody = document.getElementById('games-table');
        tbody.innerHTML = '';

        if (this.games.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center text-muted">
                        <i>暂无游戏数据</i>
                    </td>
                </tr>
            `;
            return;
        }

        this.games.forEach(game => {
            const row = document.createElement('tr');
            row.className = 'stock-row';
            
            const reviewRateClass = this.getReviewRateClass(game.review_rate);
            const priceClass = this.getPriceClass(game.current_price);
            
            const tradingButtons = this.currentUser ? `
                <button class="btn btn-sm btn-success me-1" onclick="app.showTradingModal(${game.id}, 'buy')">
                    买入
                </button>
                <button class="btn btn-sm btn-danger me-1" onclick="app.showTradingModal(${game.id}, 'sell')">
                    卖出
                </button>
            ` : '';
            
            row.innerHTML = `
                <td>
                    <strong>${game.name}</strong>
                </td>
                <td>
                    <code>${game.steam_id}</code>
                </td>
                <td>
                    ${this.formatNumber(game.sales_count)}
                </td>
                <td>
                    <span class="review-rate ${reviewRateClass}">
                        ${(game.review_rate * 100).toFixed(1)}%
                    </span>
                </td>
                <td>
                    <span class="${priceClass}">
                        $${game.current_price.toFixed(2)}
                    </span>
                </td>
                <td>
                    <small class="text-muted">
                        ${this.formatDate(game.last_updated)}
                    </small>
                </td>
                <td>
                    ${tradingButtons}
                    <button class="btn btn-sm btn-outline-primary" onclick="app.updateGameData(${game.id})">
                        更新
                    </button>
                </td>
            `;
            
            tbody.appendChild(row);
        });
    }

    // 交易相关方法
    showTradingModal(gameId, type) {
        if (!this.currentUser) {
            this.showNotification('请先登录', 'error');
            return;
        }

        const game = this.games.find(g => g.id === gameId);
        if (!game) {
            this.showNotification('游戏不存在', 'error');
            return;
        }

        document.getElementById('trading-game-id').value = gameId;
        document.getElementById('trading-type').value = type;
        document.getElementById('trading-shares').value = 1;
        
        const title = type === 'buy' ? '💰 买入股票' : '💸 卖出股票';
        document.getElementById('trading-title').textContent = title;
        
        const submitBtn = document.getElementById('trading-submit');
        submitBtn.textContent = type === 'buy' ? '确认买入' : '确认卖出';
        submitBtn.className = type === 'buy' ? 'btn btn-success' : 'btn btn-danger';
        
        document.getElementById('trading-info').innerHTML = `
            <div class="alert alert-info">
                <h6>${game.name}</h6>
                <p>当前股价: $${game.current_price.toFixed(2)}</p>
                <p>您的余额: $${this.currentUser.balance.toFixed(2)}</p>
            </div>
        `;
        
        this.updateTradingTotal();
        
        const modal = new bootstrap.Modal(document.getElementById('tradingModal'));
        modal.show();
    }

    updateTradingTotal() {
        const gameId = document.getElementById('trading-game-id').value;
        const shares = parseInt(document.getElementById('trading-shares').value) || 0;
        
        const game = this.games.find(g => g.id == gameId);
        if (game) {
            const price = game.current_price;
            const total = price * shares;
            
            document.getElementById('trading-price').textContent = `$${price.toFixed(2)}`;
            document.getElementById('trading-total').textContent = `$${total.toFixed(2)}`;
        }
    }

    async submitTrade() {
        const gameId = document.getElementById('trading-game-id').value;
        const type = document.getElementById('trading-type').value;
        const shares = parseInt(document.getElementById('trading-shares').value);

        if (!shares || shares <= 0) {
            this.showNotification('请输入有效的股数', 'error');
            return;
        }

        const endpoint = type === 'buy' ? '/api/trading/buy' : '/api/trading/sell';

        try {
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    game_id: gameId,
                    shares: shares
                })
            });

            const data = await response.json();

            if (response.ok) {
                this.showNotification(data.message, 'success');
                this.currentUser.balance = data.user_balance;
                this.updateUserInterface();
                
                // 关闭模态框
                const modal = bootstrap.Modal.getInstance(document.getElementById('tradingModal'));
                modal.hide();
            } else {
                this.showNotification(data.error, 'error');
            }
        } catch (error) {
            console.error('交易失败:', error);
            this.showNotification('交易失败: ' + error.message, 'error');
        }
    }

    // 投资组合相关方法
    async showPortfolio() {
        if (!this.currentUser) {
            this.showNotification('请先登录', 'error');
            return;
        }

        try {
            const response = await fetch('/api/trading/portfolio');
            if (response.ok) {
                const data = await response.json();
                this.renderPortfolio(data);
                
                const modal = new bootstrap.Modal(document.getElementById('portfolioModal'));
                modal.show();
            } else {
                const error = await response.json();
                this.showNotification(error.error || '获取投资组合失败', 'error');
            }
        } catch (error) {
            console.error('获取投资组合失败:', error);
            this.showNotification('获取投资组合失败: ' + error.message, 'error');
        }
    }

    renderPortfolio(data) {
        const summary = data.summary;
        const portfolios = data.portfolios;

        // 渲染摘要信息
        const summaryElement = document.getElementById('portfolio-summary');
        const profitClass = summary.total_profit_loss >= 0 ? 'text-success' : 'text-danger';
        
        summaryElement.innerHTML = `
            <div class="row">
                <div class="col-md-3">
                    <div class="card bg-primary text-white">
                        <div class="card-body text-center">
                            <h5>持股种类</h5>
                            <h3>${summary.total_stocks}</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-info text-white">
                        <div class="card-body text-center">
                            <h5>总市值</h5>
                            <h3>$${summary.total_value.toFixed(2)}</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-warning text-white">
                        <div class="card-body text-center">
                            <h5>现金余额</h5>
                            <h3>$${summary.cash_balance.toFixed(2)}</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card ${summary.total_profit_loss >= 0 ? 'bg-success' : 'bg-danger'} text-white">
                        <div class="card-body text-center">
                            <h5>总盈亏</h5>
                            <h3>$${summary.total_profit_loss.toFixed(2)}</h3>
                            <small>(${summary.total_profit_loss_percent.toFixed(2)}%)</small>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // 渲染投资组合表格
        const tbody = document.getElementById('portfolio-table');
        tbody.innerHTML = '';

        if (portfolios.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center text-muted">
                        <i>暂无持股</i>
                    </td>
                </tr>
            `;
            return;
        }

        portfolios.forEach(portfolio => {
            const row = document.createElement('tr');
            const profitClass = portfolio.profit_loss >= 0 ? 'text-success' : 'text-danger';
            
            row.innerHTML = `
                <td><strong>${portfolio.game_name}</strong></td>
                <td>${portfolio.shares}</td>
                <td>$${portfolio.avg_buy_price.toFixed(2)}</td>
                <td>$${portfolio.current_price.toFixed(2)}</td>
                <td>$${portfolio.total_value.toFixed(2)}</td>
                <td class="${profitClass}">
                    $${portfolio.profit_loss.toFixed(2)}<br>
                    <small>(${portfolio.profit_loss_percent.toFixed(2)}%)</small>
                </td>
                <td>
                    <button class="btn btn-sm btn-danger" onclick="app.showTradingModal(${portfolio.game_id}, 'sell')">
                        卖出
                    </button>
                </td>
            `;
            
            tbody.appendChild(row);
        });
    }

    async showTransactions() {
        if (!this.currentUser) {
            this.showNotification('请先登录', 'error');
            return;
        }

        try {
            const response = await fetch('/api/trading/transactions');
            if (response.ok) {
                const data = await response.json();
                console.log('交易历史:', data);
                this.showNotification('交易历史功能开发中...', 'info');
            } else {
                const error = await response.json();
                this.showNotification(error.error || '获取交易历史失败', 'error');
            }
        } catch (error) {
            console.error('获取交易历史失败:', error);
            this.showNotification('获取交易历史失败: ' + error.message, 'error');
        }
    }

    // 其他原有方法保持不变
    updateStatistics() {
        const totalStocks = this.games.length;
        const prices = this.games.map(g => g.current_price);
        const highestPrice = Math.max(...prices);
        const avgPrice = prices.reduce((a, b) => a + b, 0) / prices.length;
        
        document.getElementById('total-stocks').textContent = totalStocks;
        document.getElementById('highest-price').textContent = '$' + highestPrice.toFixed(2);
        document.getElementById('avg-price').textContent = '$' + avgPrice.toFixed(2);
        document.getElementById('last-update').textContent = new Date().toLocaleTimeString('zh-CN');
    }

    async addGame() {
        const steamId = document.getElementById('steam-id').value.trim();
        const gameName = document.getElementById('game-name').value.trim();

        if (!steamId || !gameName) {
            this.showNotification('请填写完整的游戏信息', 'error');
            return;
        }

        console.log('➕ 添加游戏:', steamId, gameName);
        
        try {
            const response = await fetch('/api/games', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    steam_id: steamId,
                    name: gameName
                })
            });

            if (response.ok) {
                const newGame = await response.json();
                this.showNotification(`成功添加游戏: ${newGame.name}`, 'success');
                
                // 清空表单
                document.getElementById('add-game-form').reset();
                
                // 重新加载数据
                await this.loadGames();
            } else {
                const error = await response.json();
                throw new Error(error.error || '添加游戏失败');
            }
        } catch (error) {
            console.error('添加游戏失败:', error);
            this.showNotification('添加游戏失败: ' + error.message, 'error');
        }
    }

    async updateGameData(gameId) {
        console.log('🔄 更新游戏数据:', gameId);
        
        try {
            const response = await fetch(`/api/games/${gameId}/update`, {
                method: 'POST'
            });

            if (response.ok) {
                const updatedGame = await response.json();
                this.showNotification(`已更新游戏: ${updatedGame.name}`, 'success');
                await this.loadGames();
            } else {
                const error = await response.json();
                throw new Error(error.error || '更新游戏数据失败');
            }
        } catch (error) {
            console.error('更新游戏数据失败:', error);
            this.showNotification('更新失败: ' + error.message, 'error');
        }
    }

    getReviewRateClass(rate) {
        if (rate >= 0.9) return 'review-excellent';
        if (rate >= 0.8) return 'review-good';
        if (rate >= 0.6) return 'review-average';
        return 'review-poor';
    }

    getPriceClass(price) {
        if (price > 5) return 'price-positive';
        if (price > 2) return 'price-neutral';
        return 'price-negative';
    }

    formatNumber(num) {
        if (num >= 1000000) {
            return (num / 1000000).toFixed(1) + 'M';
        } else if (num >= 1000) {
            return (num / 1000).toFixed(1) + 'K';
        }
        return num.toString();
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('zh-CN') + ' ' + date.toLocaleTimeString('zh-CN', {
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    showNotification(message, type = 'info') {
        const toast = document.getElementById('notification-toast');
        const toastBody = document.getElementById('toast-message');
        
        // 设置消息内容
        toastBody.textContent = message;
        
        // 设置样式
        toast.className = 'toast';
        if (type === 'success') {
            toast.classList.add('bg-success', 'text-white');
        } else if (type === 'error') {
            toast.classList.add('bg-danger', 'text-white');
        } else {
            toast.classList.add('bg-info', 'text-white');
        }
        
        // 显示Toast
        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();
        
        // 移除样式类，准备下次使用
        setTimeout(() => {
            toast.classList.remove('bg-success', 'bg-danger', 'bg-info', 'text-white');
        }, 3000);
    }
}

// 全局函数
function refreshData() {
    console.log('🔄 手动刷新数据');
    app.loadGames();
}

function showLoginModal() {
    app.showLoginModal();
}

function showRegisterModal() {
    app.showRegisterModal();
}

function submitLogin() {
    app.submitLogin();
}

function submitRegister() {
    app.submitRegister();
}

function logout() {
    app.logout();
}

function submitTrade() {
    app.submitTrade();
}

function showPortfolio() {
    app.showPortfolio();
}

function showTransactions() {
    app.showTransactions();
}

// 初始化应用
const app = new GameStockApp();

// 添加页面加载完成后的自动刷新
document.addEventListener('DOMContentLoaded', () => {
    console.log('📄 页面加载完成');
    
    // 每30秒自动刷新一次数据
    setInterval(() => {
        console.log('⏰ 自动刷新数据');
        app.loadGames();
        
        // 如果用户已登录，也刷新用户信息
        if (app.currentUser) {
            app.checkUserSession();
        }
    }, 30000);
}); 