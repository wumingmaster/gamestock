/**
 * GameStock Dashboard JavaScript
 * 现代化股票交易平台前端逻辑
 */

// 全局变量
let currentUser = null;
let stocksData = [];
let portfolioData = [];
let transactionsData = [];
let priceChart = null;
let isTableView = true;

// DOM 加载完成后初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('🎮 GameStock Dashboard v3.0 初始化中...');
    initializeApp();
});

/**
 * 初始化应用
 */
function initializeApp() {
    checkAuthStatus();
    loadStocksData();
    setupEventListeners();
    showPage('market');
}

/**
 * 检查用户认证状态
 */
async function checkAuthStatus() {
    try {
        showLoading(true);
        const response = await fetch('/api/auth/profile');
        
        if (response.ok) {
            currentUser = await response.json();
            updateAuthUI(true);
            await loadPortfolioData();
        } else {
            updateAuthUI(false);
        }
    } catch (error) {
        console.error('认证检查失败:', error);
        updateAuthUI(false);
    } finally {
        showLoading(false);
    }
}

/**
 * 更新认证相关UI
 */
function updateAuthUI(isLoggedIn) {
    const authSection = document.getElementById('auth-section');
    const userSection = document.getElementById('user-section');
    const loginBanner = document.getElementById('login-banner');
    
    if (isLoggedIn && currentUser) {
        authSection.classList.add('d-none');
        userSection.classList.remove('d-none');
        loginBanner.classList.add('d-none');
        
        document.getElementById('user-name').textContent = currentUser.username;
        document.getElementById('user-balance').textContent = formatCurrency(currentUser.balance);
    } else {
        authSection.classList.remove('d-none');
        userSection.classList.add('d-none');
        loginBanner.classList.remove('d-none');
    }
}

/**
 * 检测浏览器语言
 */
function getBrowserLanguage() {
    const language = navigator.language || navigator.userLanguage;
    return language.toLowerCase().includes('zh') ? 'zh' : 'en';
}

/**
 * 获取本地化的游戏名称
 */
function getLocalizedGameName(game) {
    const browserLang = getBrowserLanguage();
    if (browserLang === 'zh' && game.name_zh) {
        return game.name_zh;
    }
    return game.name_original || game.name;
}

/**
 * 智能图标加载函数 - 基于SteamKit思路的多重后备策略
 */
function loadGameIcon(imgElement, game, fallbackAttempt = 0) {
    const steamId = game.steam_id;
    const fallbackUrls = [
        game.icon_url || game.capsule_url,  // 主要图标URL
        `https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/${steamId}/capsule_231x87.jpg`,  // 胶囊图
        `https://steamcdn-a.akamaihd.net/steam/apps/${steamId}/capsule_184x69.jpg`,  // 小胶囊图
        `https://steamcdn-a.akamaihd.net/steam/apps/${steamId}/header.jpg`,  // 头图
        '/static/images/game-placeholder.svg'  // 最终占位符
    ];
    
    if (fallbackAttempt < fallbackUrls.length - 1) {
        const currentUrl = fallbackUrls[fallbackAttempt];
        
        // 创建新图片对象测试URL
        const testImg = new Image();
        testImg.onload = function() {
            imgElement.src = currentUrl;
            if (fallbackAttempt > 0) {
                console.log(`🖼️ 图标加载成功（第${fallbackAttempt + 1}次尝试）: ${getLocalizedGameName(game)} - ${currentUrl}`);
            }
        };
        testImg.onerror = function() {
            console.log(`❌ 图标加载失败（第${fallbackAttempt + 1}次尝试）: ${getLocalizedGameName(game)} - ${currentUrl}`);
            loadGameIcon(imgElement, game, fallbackAttempt + 1);
        };
        testImg.src = currentUrl;
    } else {
        // 所有URL都失败，使用SVG占位符
        imgElement.src = '/static/images/game-placeholder.svg';
        console.log(`🔄 所有图标URL失败，使用占位符: ${getLocalizedGameName(game)}`);
    }
}

/**
 * 初始化游戏图标加载
 */
function initializeGameIcons() {
    const gameImages = document.querySelectorAll('img[data-game]');
    gameImages.forEach(img => {
        try {
            const gameData = JSON.parse(img.getAttribute('data-game'));
            loadGameIcon(img, gameData);
        } catch (e) {
            console.error('解析游戏数据失败:', e);
            img.src = '/static/images/game-placeholder.svg';
        }
    });
}

/**
 * 加载股票数据
 */
async function loadStocksData() {
    try {
        showLoading(true);
        // 发送语言偏好给后端
        const browserLang = getBrowserLanguage();
        const headers = {
            'Accept-Language': browserLang === 'zh' ? 'zh-CN,zh;q=0.9' : 'en-US,en;q=0.9'
        };
        
        const response = await fetch('/api/games', { headers });
        
        if (response.ok) {
            stocksData = await response.json();
            stocksData.sort((a, b) => b.current_price - a.current_price);
            
            updateMarketOverview();
            renderStocksList();
            updatePriceChart();
        } else {
            showToast('加载股票数据失败', 'error');
        }
    } catch (error) {
        console.error('加载股票数据失败:', error);
        showToast('网络错误', 'error');
    } finally {
        showLoading(false);
    }
}

/**
 * 更新市场概览
 */
function updateMarketOverview() {
    if (stocksData.length === 0) return;
    
    const totalStocks = stocksData.length;
    const prices = stocksData.map(stock => stock.current_price);
    const highestPrice = Math.max(...prices);
    const avgPrice = prices.reduce((sum, price) => sum + price, 0) / prices.length;
    
    // 找到最高价格的游戏
    const highestPriceGame = stocksData.find(stock => stock.current_price === highestPrice);
    
    document.getElementById('total-stocks').textContent = totalStocks;
    document.getElementById('highest-price').textContent = formatCurrency(highestPrice);
    document.getElementById('highest-game').textContent = highestPriceGame?.name || '-';
    document.getElementById('avg-price').textContent = formatCurrency(avgPrice);
    document.getElementById('last-update').textContent = formatDateTime(new Date());
}

/**
 * 渲染股票列表
 */
function renderStocksList() {
    const tableBody = document.getElementById('stocks-table');
    const cardsContainer = document.getElementById('stocks-cards');
    
    if (isTableView) {
        renderTableView(tableBody);
    } else {
        renderCardView(cardsContainer);
    }
}

/**
 * 渲染表格视图
 */
function renderTableView(container) {
    if (!container) return;
    
    container.innerHTML = '';
    
    stocksData.forEach((stock, index) => {
        const row = document.createElement('tr');
        row.className = 'stock-row';
        row.onclick = () => showStockDetails(stock);
        
        row.innerHTML = `
            <td class="ps-3">
                <div class="stock-rank">${index + 1}</div>
            </td>
            <td>
                <div class="d-flex align-items-center">
                    <img alt="${getLocalizedGameName(stock)}" 
                         class="game-icon me-3"
                         style="width: 46px; height: 21px; border-radius: 4px; object-fit: cover;"
                         data-game='${JSON.stringify({steam_id: stock.steam_id, icon_url: stock.icon_url, capsule_url: stock.capsule_url, name: stock.name, name_zh: stock.name_zh, name_original: stock.name_original})}'>
                    <div>
                        <div class="stock-name" title="${stock.name_original || stock.name}">${getLocalizedGameName(stock)}</div>
                        <div class="stock-id">ID: ${stock.steam_id}</div>
                    </div>
                </div>
            </td>
            <td>
                <div class="fw-bold">${formatNumber(stock.positive_reviews)}</div>
                <small class="text-muted">好评数</small>
            </td>
            <td>
                <div class="fw-bold">${formatPercent(stock.review_rate)}</div>
                <div class="progress mt-1" style="height: 4px;">
                    <div class="progress-bar bg-success" style="width: ${stock.review_rate * 100}%"></div>
                </div>
            </td>
            <td>
                <div class="stock-price">${formatCurrency(stock.current_price)}</div>
            </td>
            <td>
                <div class="d-flex flex-column">
                    <small class="text-muted">${formatDateTime(stock.last_updated)}</small>
                    ${renderDataQualityBadge(stock.data_quality)}
                </div>
            </td>
            <td class="text-center">
                <div class="btn-group btn-group-sm">
                    <button class="btn btn-success" onclick="event.stopPropagation(); openTradingModal('${stock.id}', 'buy')">
                        <i class="fas fa-plus"></i> 买入
                    </button>
                    ${currentUser ? `
                        <button class="btn btn-danger" onclick="event.stopPropagation(); openTradingModal('${stock.id}', 'sell')">
                            <i class="fas fa-minus"></i> 卖出
                        </button>
                    ` : ''}
                </div>
            </td>
        `;
        
        container.appendChild(row);
    });
    
    // 初始化智能图标加载
    initializeGameIcons();
}

/**
 * 渲染卡片视图
 */
function renderCardView(container) {
    if (!container) return;
    
    container.innerHTML = '';
    
    stocksData.forEach((stock, index) => {
        const col = document.createElement('div');
        col.className = 'col-xl-3 col-lg-4 col-md-6 mb-4';
        
        col.innerHTML = `
            <div class="card stock-card h-100" onclick="showStockDetails(${JSON.stringify(stock).replace(/"/g, '&quot;')})">
                <div class="stock-rank">${index + 1}</div>
                <div class="card-body">
                    <div class="text-center mb-3">
                        <img alt="${getLocalizedGameName(stock)}" 
                             class="game-card-icon"
                             style="width: 92px; height: 43px; border-radius: 6px; object-fit: cover;"
                             data-game='${JSON.stringify({steam_id: stock.steam_id, icon_url: stock.icon_url, capsule_url: stock.capsule_url, name: stock.name, name_zh: stock.name_zh, name_original: stock.name_original})}'>
                    </div>
                    <h6 class="card-title stock-name mb-2 text-center" title="${stock.name_original || stock.name}">${getLocalizedGameName(stock)}</h6>
                    <div class="stock-id mb-3 text-center">ID: ${stock.steam_id}</div>
                    
                    <div class="row text-center mb-3">
                        <div class="col-6">
                            <div class="h6 mb-0">${formatNumber(stock.positive_reviews)}</div>
                            <small class="text-muted">好评数</small>
                        </div>
                        <div class="col-6">
                            <div class="h6 mb-0">${formatPercent(stock.review_rate)}</div>
                            <small class="text-muted">好评率</small>
                        </div>
                    </div>
                    
                    <div class="text-center mb-3">
                        <div class="stock-price h4">${formatCurrency(stock.current_price)}</div>
                    </div>
                    
                    <div class="d-grid gap-2">
                        <button class="btn btn-success btn-sm" onclick="event.stopPropagation(); openTradingModal('${stock.id}', 'buy')">
                            <i class="fas fa-plus me-1"></i>买入
                        </button>
                        ${currentUser ? `
                            <button class="btn btn-outline-danger btn-sm" onclick="event.stopPropagation(); openTradingModal('${stock.id}', 'sell')">
                                <i class="fas fa-minus me-1"></i>卖出
                            </button>
                        ` : ''}
                    </div>
                </div>
            </div>
        `;
        
        container.appendChild(col);
    });
    
    // 初始化智能图标加载
    initializeGameIcons();
}

/**
 * 显示页面
 */
function showPage(pageName) {
    // 隐藏所有页面
    document.querySelectorAll('.page').forEach(page => {
        page.classList.remove('active');
        page.classList.add('d-none');
    });
    
    // 显示指定页面
    const targetPage = document.getElementById(`${pageName}-page`);
    if (targetPage) {
        targetPage.classList.add('active');
        targetPage.classList.remove('d-none');
    }
    
    // 更新导航状态
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });
    
    const activeLink = document.querySelector(`[onclick="showPage('${pageName}')"]`);
    if (activeLink) {
        activeLink.classList.add('active');
    }
    
    // 根据页面加载相应数据
    switch (pageName) {
        case 'portfolio':
            if (currentUser) {
                loadPortfolioData();
            } else {
                showLoginModal();
            }
            break;
        case 'transactions':
            if (currentUser) {
                loadTransactionsData();
            } else {
                showLoginModal();
            }
            break;
        case 'analysis':
            updatePriceChart();
            break;
    }
}

/**
 * 切换视图模式
 */
function toggleViewMode() {
    isTableView = !isTableView;
    const tableView = document.getElementById('table-view');
    const cardView = document.getElementById('card-view');
    const viewIcon = document.getElementById('view-icon');
    
    if (isTableView) {
        tableView.classList.remove('d-none');
        cardView.classList.add('d-none');
        viewIcon.className = 'fas fa-th-large';
    } else {
        tableView.classList.add('d-none');
        cardView.classList.remove('d-none');
        viewIcon.className = 'fas fa-table';
    }
    
    renderStocksList();
}

/**
 * 筛选股票
 */
function filterStocks() {
    const searchTerm = document.getElementById('search-input').value.toLowerCase();
    const rows = document.querySelectorAll('.stock-row');
    const cards = document.querySelectorAll('.stock-card');
    
    (isTableView ? rows : cards).forEach(element => {
        const text = element.textContent.toLowerCase();
        element.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

/**
 * 排序股票
 */
function sortStocks() {
    const sortBy = document.getElementById('sort-select').value;
    
    switch (sortBy) {
        case 'price-desc':
            stocksData.sort((a, b) => b.current_price - a.current_price);
            break;
        case 'price-asc':
            stocksData.sort((a, b) => a.current_price - b.current_price);
            break;
        case 'name-asc':
            stocksData.sort((a, b) => a.name.localeCompare(b.name));
            break;
        case 'reviews-desc':
            stocksData.sort((a, b) => b.positive_reviews - a.positive_reviews);
            break;
        case 'rate-desc':
            stocksData.sort((a, b) => b.review_rate - a.review_rate);
            break;
    }
    
    renderStocksList();
}

/**
 * 渲染数据质量徽章
 */
function renderDataQualityBadge(dataQuality) {
    if (!dataQuality) return '';
    
    const { accuracy, freshness, is_realtime, age_hours } = dataQuality;
    
    let badgeClass = 'bg-secondary';
    let badgeText = '未知';
    let tooltip = '数据状态未知';
    
    if (accuracy === 'accurate' && is_realtime) {
        badgeClass = 'bg-success';
        badgeText = '实时';
        tooltip = `数据来源: Steam API (${age_hours}小时前更新)`;
    } else if (accuracy === 'accurate' && !is_realtime) {
        badgeClass = 'bg-warning';
        badgeText = '过时';
        tooltip = `数据来源: Steam API (${age_hours}小时前更新，建议刷新)`;
    } else {
        badgeClass = 'bg-danger';
        badgeText = '错误';
        tooltip = '数据获取失败，请刷新';
    }
    
    return `<span class="badge ${badgeClass} text-white" style="font-size: 10px;" title="${tooltip}">${badgeText}</span>`;
}

/**
 * 刷新数据
 */
async function refreshData() {
    await loadStocksData();
    showToast('数据已刷新', 'success');
}

/**
 * 刷新所有Steam数据
 */
async function refreshAllSteamData() {
    try {
        showLoading(true);
        showToast('正在从Steam API获取最新数据...', 'info');
        
        const response = await fetch('/api/games/refresh-all', {
            method: 'POST'
        });
        
        if (response.ok) {
            const result = await response.json();
            showToast(result.message, 'success');
            
            // 显示详细更新结果
            showRefreshDetails(result);
            
            // 重新加载股票数据
            await loadStocksData();
        } else {
            const error = await response.json();
            showToast(error.message || '数据刷新失败', 'error');
        }
    } catch (error) {
        console.error('刷新Steam数据失败:', error);
        showToast('网络错误，无法刷新数据', 'error');
    } finally {
        showLoading(false);
    }
}

/**
 * 显示数据刷新详情
 */
function showRefreshDetails(result) {
    const modal = new bootstrap.Modal(document.createElement('div'));
    const modalHtml = `
        <div class="modal fade" tabindex="-1">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-sync-alt text-primary me-2"></i>
                            Steam数据刷新结果
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="row mb-4">
                            <div class="col-md-4">
                                <div class="card text-center border-success">
                                    <div class="card-body">
                                        <i class="fas fa-check-circle text-success fa-2x mb-2"></i>
                                        <h4 class="text-success">${result.summary.successful_updates}</h4>
                                        <small class="text-muted">成功更新</small>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="card text-center border-danger">
                                    <div class="card-body">
                                        <i class="fas fa-exclamation-circle text-danger fa-2x mb-2"></i>
                                        <h4 class="text-danger">${result.summary.failed_updates}</h4>
                                        <small class="text-muted">更新失败</small>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="card text-center border-info">
                                    <div class="card-body">
                                        <i class="fas fa-percentage text-info fa-2x mb-2"></i>
                                        <h4 class="text-info">${result.summary.success_rate}</h4>
                                        <small class="text-muted">成功率</small>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="table-responsive">
                            <table class="table table-sm">
                                <thead>
                                    <tr>
                                        <th>游戏名称</th>
                                        <th>状态</th>
                                        <th>股价变化</th>
                                        <th>好评数</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${result.details.map(detail => `
                                        <tr>
                                            <td>
                                                <strong>${detail.game_name}</strong>
                                                <br><small class="text-muted">ID: ${detail.steam_id}</small>
                                            </td>
                                            <td>
                                                <span class="badge ${detail.status === 'updated' ? 'bg-success' : 'bg-danger'}">
                                                    ${detail.status === 'updated' ? '已更新' : '失败'}
                                                </span>
                                            </td>
                                            <td>
                                                ${detail.status === 'updated' ? 
                                                    `${detail.old_price} → ${detail.new_price} (${detail.price_change})` : 
                                                    `<small class="text-muted">${detail.error || '无法获取'}</small>`
                                                }
                                            </td>
                                            <td>
                                                ${detail.status === 'updated' ? 
                                                    formatNumber(detail.positive_reviews) : 
                                                    '<small class="text-muted">-</small>'
                                                }
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">关闭</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    const modalElement = document.body.lastElementChild;
    const bootstrapModal = new bootstrap.Modal(modalElement);
    
    modalElement.addEventListener('hidden.bs.modal', () => {
        modalElement.remove();
    });
    
    bootstrapModal.show();
}

/**
 * 显示股票详情
 */
function showStockDetails(stock) {
    // 这里可以打开一个详情模态框或跳转到详情页面
    console.log('股票详情:', stock);
}

/**
 * 打开交易模态框
 */
function openTradingModal(gameId, type) {
    if (!currentUser) {
        showLoginModal();
        return;
    }
    
    const stock = stocksData.find(s => s.id == gameId);
    if (!stock) {
        showToast('股票信息不存在', 'error');
        return;
    }
    
    const modal = new bootstrap.Modal(document.getElementById('tradingModal'));
    const title = document.getElementById('trading-title');
    const info = document.getElementById('trading-info');
    const submitBtn = document.getElementById('trading-submit');
    
    document.getElementById('trading-game-id').value = gameId;
    document.getElementById('trading-type').value = type;
    document.getElementById('trading-price').value = stock.current_price.toFixed(2);
    document.getElementById('trading-shares').value = 1;
    
    title.innerHTML = `
        <i class="fas fa-exchange-alt text-primary me-2"></i>
        ${type === 'buy' ? '买入' : '卖出'} ${getLocalizedGameName(stock)}
    `;
    
    info.innerHTML = `
        <div class="card bg-light">
            <div class="card-body">
                                  <div class="row">
                      <div class="col-md-2 text-center">
                         <img alt="${getLocalizedGameName(stock)}" 
                              class="trading-game-icon"
                              style="width: 60px; height: 28px; border-radius: 4px; object-fit: cover;"
                              data-game='${JSON.stringify({steam_id: stock.steam_id, icon_url: stock.icon_url, capsule_url: stock.capsule_url, name: stock.name, name_zh: stock.name_zh, name_original: stock.name_original})}'>
                      </div>
                    <div class="col-md-6">
                        <h6 class="card-title" title="${stock.name_original || stock.name}">${getLocalizedGameName(stock)}</h6>
                        <div class="small text-muted mb-2">Steam ID: ${stock.steam_id}</div>
                        <div class="small">
                            好评数: <strong>${formatNumber(stock.positive_reviews)}</strong> | 
                            好评率: <strong>${formatPercent(stock.review_rate)}</strong>
                        </div>
                    </div>
                    <div class="col-md-4 text-end">
                        <div class="h5 text-success">${formatCurrency(stock.current_price)}</div>
                        <div class="small text-muted">当前股价</div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    submitBtn.className = type === 'buy' ? 'btn btn-success' : 'btn btn-danger';
    submitBtn.innerHTML = `
        <i class="fas fa-${type === 'buy' ? 'plus' : 'minus'} me-1"></i>
        确认${type === 'buy' ? '买入' : '卖出'}
    `;
    
    updateTradingTotal();
    modal.show();
    
    // 初始化模态框中的图标
    setTimeout(() => initializeGameIcons(), 100);
}

/**
 * 调整股数
 */
function adjustShares(delta) {
    const sharesInput = document.getElementById('trading-shares');
    const currentShares = parseInt(sharesInput.value) || 1;
    const newShares = Math.max(1, currentShares + delta);
    sharesInput.value = newShares;
    updateTradingTotal();
}

/**
 * 更新交易总额
 */
function updateTradingTotal() {
    const shares = parseInt(document.getElementById('trading-shares').value) || 1;
    const price = parseFloat(document.getElementById('trading-price').value) || 0;
    const total = shares * price;
    
    document.getElementById('trading-total').textContent = formatCurrency(total);
}

/**
 * 提交交易
 */
async function submitTrade() {
    const gameId = document.getElementById('trading-game-id').value;
    const type = document.getElementById('trading-type').value;
    const shares = parseInt(document.getElementById('trading-shares').value);
    
    if (!gameId || !type || !shares || shares < 1) {
        showToast('请检查交易参数', 'error');
        return;
    }
    
    try {
        showLoading(true);
        
        const response = await fetch(`/api/trading/${type}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                game_id: parseInt(gameId),
                shares: shares
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showToast(data.message, 'success');
            
            // 更新用户余额
            currentUser.balance = data.user_balance;
            updateAuthUI(true);
            
            // 关闭模态框
            bootstrap.Modal.getInstance(document.getElementById('tradingModal')).hide();
            
            // 刷新相关数据
            await loadPortfolioData();
        } else {
            showToast(data.error || '交易失败', 'error');
        }
    } catch (error) {
        console.error('交易失败:', error);
        showToast('网络错误', 'error');
    } finally {
        showLoading(false);
    }
}

/**
 * 加载投资组合数据
 */
async function loadPortfolioData() {
    if (!currentUser) return;
    
    try {
        const response = await fetch('/api/trading/portfolio');
        
        if (response.ok) {
            portfolioData = await response.json();
            renderPortfolio();
        } else {
            showToast('加载投资组合失败', 'error');
        }
    } catch (error) {
        console.error('加载投资组合失败:', error);
    }
}

/**
 * 渲染投资组合
 */
function renderPortfolio() {
    const overviewContainer = document.getElementById('portfolio-overview');
    const holdingsContainer = document.getElementById('portfolio-holdings');
    
    if (!portfolioData || !portfolioData.summary) return;
    
    const summary = portfolioData.summary;
    
    // 渲染概览卡片
    overviewContainer.innerHTML = `
        <div class="col-xl-3 col-md-6 mb-3">
            <div class="card stats-card">
                <div class="card-body">
                    <div class="d-flex align-items-center">
                        <div class="avatar bg-primary-soft">
                            <i class="fas fa-chart-pie text-primary"></i>
                        </div>
                        <div class="ms-3">
                            <div class="h6 mb-1">总资产</div>
                            <div class="h4 mb-0">${formatCurrency(summary.total_assets)}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-md-6 mb-3">
            <div class="card stats-card success">
                <div class="card-body">
                    <div class="d-flex align-items-center">
                        <div class="avatar bg-success-soft">
                            <i class="fas fa-wallet text-success"></i>
                        </div>
                        <div class="ms-3">
                            <div class="h6 mb-1">现金余额</div>
                            <div class="h4 mb-0">${formatCurrency(summary.cash_balance)}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-md-6 mb-3">
            <div class="card stats-card info">
                <div class="card-body">
                    <div class="d-flex align-items-center">
                        <div class="avatar bg-info-soft">
                            <i class="fas fa-chart-line text-info"></i>
                        </div>
                        <div class="ms-3">
                            <div class="h6 mb-1">股票价值</div>
                            <div class="h4 mb-0">${formatCurrency(summary.total_value)}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-md-6 mb-3">
            <div class="card stats-card ${summary.total_profit_loss >= 0 ? 'success' : 'warning'}">
                <div class="card-body">
                    <div class="d-flex align-items-center">
                        <div class="avatar bg-${summary.total_profit_loss >= 0 ? 'success' : 'warning'}-soft">
                            <i class="fas fa-${summary.total_profit_loss >= 0 ? 'arrow-up' : 'arrow-down'} text-${summary.total_profit_loss >= 0 ? 'success' : 'warning'}"></i>
                        </div>
                        <div class="ms-3">
                            <div class="h6 mb-1">总盈亏</div>
                            <div class="h4 mb-0 text-${summary.total_profit_loss >= 0 ? 'success' : 'danger'}">${formatCurrency(summary.total_profit_loss)}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // 渲染持股列表
    if (portfolioData.portfolios && portfolioData.portfolios.length > 0) {
        holdingsContainer.innerHTML = portfolioData.portfolios.map(holding => `
            <tr>
                <td class="ps-3">
                    <div class="fw-bold">${holding.game_name}</div>
                    <small class="text-muted">ID: ${holding.game_steam_id}</small>
                </td>
                <td>${holding.shares}</td>
                <td>${formatCurrency(holding.avg_buy_price)}</td>
                <td>${formatCurrency(holding.current_price)}</td>
                <td>${formatCurrency(holding.total_value)}</td>
                <td>
                    <div class="profit-indicator ${holding.profit_loss >= 0 ? 'positive' : 'negative'}">
                        <i class="fas fa-${holding.profit_loss >= 0 ? 'arrow-up' : 'arrow-down'}"></i>
                        ${formatCurrency(holding.profit_loss)} (${holding.profit_loss_percent.toFixed(2)}%)
                    </div>
                </td>
                <td class="text-center">
                    <button class="btn btn-danger btn-sm" onclick="openTradingModal('${holding.game_id}', 'sell')">
                        <i class="fas fa-minus"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    } else {
        holdingsContainer.innerHTML = `
            <tr>
                <td colspan="7" class="text-center py-4">
                    <i class="fas fa-chart-pie fa-3x text-muted mb-3"></i>
                    <div class="h5 text-muted">暂无持股</div>
                    <p class="text-muted">开始您的第一笔投资吧！</p>
                </td>
            </tr>
        `;
    }
}

/**
 * 加载交易历史数据
 */
async function loadTransactionsData() {
    if (!currentUser) return;
    
    try {
        const response = await fetch('/api/trading/transactions');
        
        if (response.ok) {
            const data = await response.json();
            transactionsData = data.transactions;
            renderTransactions();
        } else {
            showToast('加载交易历史失败', 'error');
        }
    } catch (error) {
        console.error('加载交易历史失败:', error);
    }
}

/**
 * 渲染交易历史
 */
function renderTransactions() {
    const container = document.getElementById('transactions-list');
    
    if (transactionsData && transactionsData.length > 0) {
        container.innerHTML = transactionsData.map(transaction => `
            <tr>
                <td class="ps-3">
                    <div>${formatDateTime(transaction.created_at)}</div>
                </td>
                <td>
                    <span class="badge bg-${transaction.transaction_type === 'buy' ? 'success' : 'danger'}">
                        <i class="fas fa-${transaction.transaction_type === 'buy' ? 'plus' : 'minus'} me-1"></i>
                        ${transaction.transaction_type === 'buy' ? '买入' : '卖出'}
                    </span>
                </td>
                <td>
                    <div class="fw-bold">${transaction.game_name}</div>
                    <small class="text-muted">ID: ${transaction.game_steam_id}</small>
                </td>
                <td>${transaction.shares}</td>
                <td>${formatCurrency(transaction.price_per_share)}</td>
                <td class="fw-bold">${formatCurrency(transaction.total_amount)}</td>
            </tr>
        `).join('');
    } else {
        container.innerHTML = `
            <tr>
                <td colspan="6" class="text-center py-4">
                    <i class="fas fa-history fa-3x text-muted mb-3"></i>
                    <div class="h5 text-muted">暂无交易记录</div>
                    <p class="text-muted">进行您的第一笔交易吧！</p>
                </td>
            </tr>
        `;
    }
}

/**
 * 更新价格图表
 */
function updatePriceChart() {
    const ctx = document.getElementById('price-chart');
    if (!ctx || stocksData.length === 0) return;
    
    if (priceChart) {
        priceChart.destroy();
    }
    
    const labels = stocksData.slice(0, 10).map(stock => stock.name.length > 10 ? stock.name.substring(0, 10) + '...' : stock.name);
    const prices = stocksData.slice(0, 10).map(stock => stock.current_price);
    
    priceChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: '股价 ($)',
                data: prices,
                backgroundColor: 'rgba(13, 110, 253, 0.1)',
                borderColor: 'rgba(13, 110, 253, 1)',
                borderWidth: 2,
                borderRadius: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return '$' + value;
                        }
                    }
                }
            }
        }
    });
}

/**
 * 认证相关函数
 */
function showLoginModal() {
    const modal = new bootstrap.Modal(document.getElementById('loginModal'));
    modal.show();
}

function showRegisterModal() {
    const modal = new bootstrap.Modal(document.getElementById('registerModal'));
    modal.show();
}

async function submitLogin() {
    const username = document.getElementById('login-username').value;
    const password = document.getElementById('login-password').value;
    
    if (!username || !password) {
        showToast('请输入用户名和密码', 'error');
        return;
    }
    
    try {
        showLoading(true);
        
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username, password })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            currentUser = data.user;
            updateAuthUI(true);
            bootstrap.Modal.getInstance(document.getElementById('loginModal')).hide();
            showToast('登录成功', 'success');
            await loadPortfolioData();
        } else {
            showToast(data.error || '登录失败', 'error');
        }
    } catch (error) {
        console.error('登录失败:', error);
        showToast('网络错误', 'error');
    } finally {
        showLoading(false);
    }
}

async function submitRegister() {
    const username = document.getElementById('register-username').value;
    const email = document.getElementById('register-email').value;
    const password = document.getElementById('register-password').value;
    const confirm = document.getElementById('register-confirm').value;
    
    if (!username || !email || !password || !confirm) {
        showToast('请填写所有字段', 'error');
        return;
    }
    
    if (password !== confirm) {
        showToast('密码确认不匹配', 'error');
        return;
    }
    
    try {
        showLoading(true);
        
        const response = await fetch('/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username, email, password })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            currentUser = data.user;
            updateAuthUI(true);
            bootstrap.Modal.getInstance(document.getElementById('registerModal')).hide();
            showToast('注册成功', 'success');
            await loadPortfolioData();
        } else {
            showToast(data.error || '注册失败', 'error');
        }
    } catch (error) {
        console.error('注册失败:', error);
        showToast('网络错误', 'error');
    } finally {
        showLoading(false);
    }
}

async function logout() {
    try {
        await fetch('/api/auth/logout', { method: 'POST' });
        currentUser = null;
        portfolioData = [];
        transactionsData = [];
        updateAuthUI(false);
        showPage('market');
        showToast('已退出登录', 'success');
    } catch (error) {
        console.error('退出登录失败:', error);
    }
}

/**
 * 其他工具函数
 */
function showAddGameModal() {
    const modal = new bootstrap.Modal(document.getElementById('addGameModal'));
    modal.show();
}

async function submitAddGame() {
    const steamId = document.getElementById('steam-id').value;
    const gameName = document.getElementById('game-name').value;
    
    if (!steamId || !gameName) {
        showToast('请填写所有字段', 'error');
        return;
    }
    
    try {
        showLoading(true);
        
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
        
        const data = await response.json();
        
        if (response.ok) {
            bootstrap.Modal.getInstance(document.getElementById('addGameModal')).hide();
            showToast('游戏添加成功', 'success');
            await refreshData();
            
            // 清空表单
            document.getElementById('steam-id').value = '';
            document.getElementById('game-name').value = '';
        } else {
            showToast(data.error || '添加游戏失败', 'error');
        }
    } catch (error) {
        console.error('添加游戏失败:', error);
        showToast('网络错误', 'error');
    } finally {
        showLoading(false);
    }
}

function setupEventListeners() {
    // 搜索输入框回车事件
    document.getElementById('search-input').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            filterStocks();
        }
    });
    
    // 交易股数输入事件
    document.getElementById('trading-shares').addEventListener('input', updateTradingTotal);
}

function showLoading(show) {
    const overlay = document.getElementById('loading-overlay');
    if (overlay) {
        overlay.classList.toggle('d-none', !show);
    }
}

function showToast(message, type = 'info') {
    const toast = document.getElementById('notification-toast');
    const toastMessage = document.getElementById('toast-message');
    
    if (toast && toastMessage) {
        toastMessage.textContent = message;
        
        // 设置Toast颜色
        toast.className = `toast bg-${type === 'error' ? 'danger' : type} text-white`;
        
        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();
    }
}

// 格式化函数
function formatCurrency(amount) {
    return '$' + Number(amount).toFixed(2);
}

function formatNumber(num) {
    return Number(num).toLocaleString();
}

function formatPercent(rate) {
    return (rate * 100).toFixed(1) + '%';
}

function formatDateTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// ========== 充值相关功能 ==========

/**
 * 显示充值模态框
 */
function showRechargeModal() {
    if (!currentUser) {
        showToast('请先登录', 'error');
        return;
    }
    
    const modal = new bootstrap.Modal(document.getElementById('rechargeModal'));
    modal.show();
}

/**
 * 提交充值请求
 */
async function submitRecharge() {
    const paymentMethod = document.getElementById('payment-method').value;
    
    try {
        showLoading(true);
        
        const response = await fetch('/api/payment/recharge', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                amount: 4.99,
                payment_method: paymentMethod
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            // 充值成功
            showToast('充值成功！账户已到账 $100,000 虚拟资金', 'success');
            
            // 更新用户余额
            currentUser.balance = data.user.balance;
            updateAuthUI(true);
            
            // 关闭模态框
            bootstrap.Modal.getInstance(document.getElementById('rechargeModal')).hide();
            
            // 显示详细信息
            showRechargeSuccessDetails(data);
            
        } else {
            showToast(data.error || '充值失败', 'error');
        }
    } catch (error) {
        console.error('充值失败:', error);
        showToast('网络错误，充值失败', 'error');
    } finally {
        showLoading(false);
    }
}

/**
 * 显示充值成功详情
 */
function showRechargeSuccessDetails(data) {
    const details = `
        <div class="alert alert-success">
            <h5><i class="fas fa-check-circle me-2"></i>充值成功！</h5>
            <hr>
            <div class="row">
                <div class="col-md-6">
                    <strong>支付详情：</strong><br>
                    支付金额: ${data.payment_details.amount_paid}<br>
                    获得资金: ${data.payment_details.virtual_funds_received}<br>
                    兑换比率: ${data.payment_details.exchange_rate}
                </div>
                <div class="col-md-6">
                    <strong>账户更新：</strong><br>
                    原余额: ${data.account_update.old_balance}<br>
                    新余额: ${data.account_update.new_balance}<br>
                    增加金额: ${data.account_update.increase}
                </div>
            </div>
            <hr>
            <small><strong>交易ID:</strong> ${data.transaction_id}</small>
        </div>
    `;
    
    // 创建一个临时模态框显示详情
    const tempModal = document.createElement('div');
    tempModal.className = 'modal fade';
    tempModal.innerHTML = `
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow">
                <div class="modal-header border-0">
                    <h5 class="modal-title text-success">
                        <i class="fas fa-credit-card me-2"></i>充值完成
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    ${details}
                </div>
                <div class="modal-footer border-0">
                    <button type="button" class="btn btn-success" data-bs-dismiss="modal">确定</button>
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(tempModal);
    const modal = new bootstrap.Modal(tempModal);
    modal.show();
    
    // 模态框关闭后删除元素
    tempModal.addEventListener('hidden.bs.modal', () => {
        document.body.removeChild(tempModal);
    });
}

/**
 * 显示充值历史
 */
async function showRechargeHistory() {
    if (!currentUser) {
        showToast('请先登录', 'error');
        return;
    }
    
    const modal = new bootstrap.Modal(document.getElementById('rechargeHistoryModal'));
    modal.show();
    
    try {
        const response = await fetch('/api/payment/history');
        
        if (response.ok) {
            const data = await response.json();
            renderRechargeHistory(data);
        } else {
            document.getElementById('recharge-history-content').innerHTML = `
                <div class="text-center py-4">
                    <i class="fas fa-exclamation-triangle fa-3x text-warning mb-3"></i>
                    <h5>加载失败</h5>
                    <p class="text-muted">无法获取充值历史记录</p>
                </div>
            `;
        }
    } catch (error) {
        console.error('获取充值历史失败:', error);
        document.getElementById('recharge-history-content').innerHTML = `
            <div class="text-center py-4">
                <i class="fas fa-wifi fa-3x text-danger mb-3"></i>
                <h5>网络错误</h5>
                <p class="text-muted">请检查网络连接后重试</p>
            </div>
        `;
    }
}

/**
 * 渲染充值历史
 */
function renderRechargeHistory(data) {
    const container = document.getElementById('recharge-history-content');
    
    if (data.recharge_history.length === 0) {
        container.innerHTML = `
            <div class="text-center py-5">
                <i class="fas fa-credit-card fa-3x text-muted mb-3"></i>
                <h5>暂无充值记录</h5>
                <p class="text-muted">您还没有进行过充值</p>
                <button class="btn btn-success" onclick="bootstrap.Modal.getInstance(document.getElementById('rechargeHistoryModal')).hide(); showRechargeModal();">
                    <i class="fas fa-plus me-1"></i>立即充值
                </button>
            </div>
        `;
        return;
    }
    
    const totalStats = `
        <div class="row mb-4">
            <div class="col-md-6">
                <div class="card border-primary">
                    <div class="card-body text-center">
                        <h5 class="text-primary">累计充值</h5>
                        <div class="h3">${formatCurrency(data.total_recharged)}</div>
                        <small class="text-muted">真实货币</small>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card border-success">
                    <div class="card-body text-center">
                        <h5 class="text-success">获得资金</h5>
                        <div class="h3">${formatCurrency(data.total_virtual_funds)}</div>
                        <small class="text-muted">虚拟资金</small>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    const historyTable = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead class="table-light">
                    <tr>
                        <th>时间</th>
                        <th>支付金额</th>
                        <th>获得资金</th>
                        <th>支付方式</th>
                        <th>状态</th>
                        <th>交易ID</th>
                    </tr>
                </thead>
                <tbody>
                    ${data.recharge_history.map(record => `
                        <tr>
                            <td>${formatDateTime(record.created_at)}</td>
                            <td><span class="badge bg-primary">${formatCurrency(record.payment_amount)}</span></td>
                            <td><span class="badge bg-success">${formatCurrency(record.virtual_funds)}</span></td>
                            <td>
                                <i class="fas fa-${getPaymentIcon(record.payment_method)} me-1"></i>
                                ${getPaymentName(record.payment_method)}
                            </td>
                            <td>
                                <span class="badge bg-${record.status === 'completed' ? 'success' : record.status === 'failed' ? 'danger' : 'warning'}">
                                    ${getStatusName(record.status)}
                                </span>
                            </td>
                            <td><small class="text-muted">${record.transaction_id}</small></td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    container.innerHTML = totalStats + historyTable;
}

/**
 * 获取支付方式图标
 */
function getPaymentIcon(method) {
    const icons = {
        'credit_card': 'credit-card',
        'paypal': 'paypal',
        'apple_pay': 'apple',
        'google_pay': 'google'
    };
    return icons[method] || 'credit-card';
}

/**
 * 获取支付方式名称
 */
function getPaymentName(method) {
    const names = {
        'credit_card': '信用卡',
        'paypal': 'PayPal',
        'apple_pay': 'Apple Pay',
        'google_pay': 'Google Pay'
    };
    return names[method] || method;
}

/**
 * 获取状态名称
 */
function getStatusName(status) {
    const names = {
        'completed': '已完成',
        'pending': '处理中',
        'failed': '失败'
    };
    return names[status] || status;
}

// 导出全局函数（为了模板中的onclick事件）
window.showPage = showPage;
window.toggleViewMode = toggleViewMode;
window.filterStocks = filterStocks;
window.sortStocks = sortStocks;
window.refreshData = refreshData;
window.showStockDetails = showStockDetails;
window.openTradingModal = openTradingModal;
window.adjustShares = adjustShares;
window.updateTradingTotal = updateTradingTotal;
window.submitTrade = submitTrade;
window.showLoginModal = showLoginModal;
window.showRegisterModal = showRegisterModal;
window.submitLogin = submitLogin;
window.submitRegister = submitRegister;
window.logout = logout;
window.showAddGameModal = showAddGameModal;
window.submitAddGame = submitAddGame;
window.showRechargeModal = showRechargeModal;
window.submitRecharge = submitRecharge;
window.showRechargeHistory = showRechargeHistory; 