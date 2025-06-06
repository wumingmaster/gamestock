//
//  TradingViewModel.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import Foundation
import Combine

@MainActor
class TradingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var game: Game?
    @Published var tradingType: TradingType = .buy
    @Published var quantity: Int = 1
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isTransactionSuccessful = false
    @Published var availableCash: Double = 0.0
    
    // 用户数据
    @Published var currentHolding: Int = 0
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private let userService = UserService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 交易总金额
    var totalAmount: Double {
        guard let game = game else { return 0.0 }
        return game.currentPrice * Double(quantity)
    }
    
    /// 格式化的交易总金额
    var formattedTotalAmount: String {
        return String(format: "$%.2f", totalAmount)
    }
    
    /// 是否可以执行交易
    var canExecuteTrade: Bool {
        guard game != nil else { return false }
        
        switch tradingType {
        case .buy:
            return totalAmount <= availableCash && quantity > 0
        case .sell:
            return currentHolding >= quantity && quantity > 0
        }
    }
    
    /// 最大可交易数量
    var maxQuantity: Int {
        guard let game = game else { return 0 }
        
        switch tradingType {
        case .buy:
            return Int(availableCash / game.currentPrice)
        case .sell:
            return currentHolding
        }
    }
    
    // MARK: - Initialization
    init(game: Game? = nil) {
        self.game = game
        loadUserData()
    }
    
    // MARK: - Public Methods
    
    /// 设置最大数量
    func setMaxQuantity() {
        let max = maxQuantity
        if max > 0 {
            quantity = max
        }
    }
    
    /// 增加数量
    func increaseQuantity() {
        let max = maxQuantity
        if max > 0 {
            if quantity < max {
                quantity += 1
            }
        }
    }
    
    /// 减少数量
    func decreaseQuantity() {
        if quantity > 1 {
            quantity -= 1
        }
    }
    
    /// 执行交易
    func executeTrade() {
        guard let game = game, canExecuteTrade else {
            print("❌ 交易条件不满足")
            print("  - 游戏: \(game?.name ?? "无")")
            print("  - 可交易: \(canExecuteTrade)")
            showError("交易条件不满足")
            return
        }
        
        print("💰 开始交易操作")
        print("  - 游戏: \(game.name) (ID: \(game.id))")
        print("  - 交易类型: \(tradingType == .buy ? "买入" : "卖出")")
        print("  - 数量: \(quantity)")
        print("  - 单价: $\(game.currentPrice)")
        print("  - 总价: $\(totalAmount)")
        
        isLoading = true
        
        // 在交易前先确保用户已登录
        print("🔐 开始交易流程，先确保用户已登录...")
        
        networkManager.autoLoginTestUser()
            .handleEvents(
                receiveOutput: { response in
                    print("🔑 登录响应详情:")
                    print("  - 用户名: \(response.username)")
                    print("  - 余额: $\(response.balance)")
                }
            )
            .flatMap { [weak self] loginResponse -> AnyPublisher<TransactionResponse, NetworkError> in
                print("✅ 登录成功，开始执行交易...")
                
                guard let self = self, let game = self.game else {
                    print("❌ 自引用或游戏对象丢失")
                    return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
                }
                
                print("🛒 发送交易请求:")
                print("  - 游戏ID: \(game.id)")
                print("  - 交易数量: \(self.quantity)")
                print("  - 交易类型: \(self.tradingType == .buy ? "买入" : "卖出")")
                
                if self.tradingType == .buy {
                    return self.networkManager.buyStock(gameId: game.id, quantity: self.quantity)
                        .handleEvents(
                            receiveSubscription: { _ in
                                print("📡 买入请求已发送...")
                            }
                        )
                        .eraseToAnyPublisher()
                } else {
                    return self.networkManager.sellStock(gameId: game.id, quantity: self.quantity)
                        .handleEvents(
                            receiveSubscription: { _ in
                                print("📡 卖出请求已发送...")
                            }
                        )
                        .eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    print("🏁 交易流程完成")
                    
                    if case .failure(let error) = completion {
                        print("❌ 交易失败详情: \(error)")
                        if self?.tradingType == .buy {
                            self?.showError("买入失败: \(error.localizedDescription)")
                        } else {
                            self?.showError("卖出失败: \(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    print("📈 ========== 交易响应 ==========")
                    print("📈 成功: \(response.success)")
                    print("📈 消息: \(response.actualMessage)")
                    if let balance = response.newBalance {
                        print("📈 新余额: $\(String(format: "%.2f", balance))")
                    }
                    
                    // 如果有交易详情，打印出来
                    if let transaction = response.transaction {
                        print("📈 交易详情:")
                        print("📈   - 交易ID: \(transaction.id)")
                        print("📈   - 游戏ID: \(transaction.gameId)")
                        print("📈   - 类型: \(transaction.type)")
                        print("📈   - 股数: \(transaction.shares)")
                        print("📈   - 价格: $\(String(format: "%.2f", transaction.price))")
                        print("📈   - 时间: \(transaction.timestamp)")
                    }
                    
                    // 如果有投资组合信息，打印出来
                    if let portfolio = response.portfolio {
                        print("📈 更新后的投资组合:")
                        print("📈   - 游戏ID: \(portfolio.gameId)")
                        print("📈   - 持股数: \(portfolio.shares)")
                        print("📈   - 平均成本: $\(String(format: "%.2f", portfolio.avgBuyPrice))")
                        print("📈   - 当前价格: $\(String(format: "%.2f", portfolio.currentPrice))")
                        print("📈   - 总价值: $\(String(format: "%.2f", portfolio.totalValue))")
                        print("📈   - 盈亏: $\(String(format: "%.2f", portfolio.profitLoss))")
                    }
                    print("📈 ===============================")
                    
                    self?.handleTransactionResponse(response)
                    
                    // 交易完成后2秒再次获取最新投资组合信息
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.logLatestPortfolio()
                    }
                }
            )
            .store(in: &cancellables)
        

    }
    
    // MARK: - Private Methods
    
    /// 加载用户数据
    func loadUserData() {
        print("🔄 开始加载用户数据...")
        
        // 加载投资组合（包含现金余额和持仓信息）
        guard let game = game else { 
            print("❌ 游戏信息为空，无法加载用户数据")
            return 
        }
        
        networkManager.fetchPortfolio()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ 投资组合数据加载完成")
                    case .failure(let error):
                        print("❌ 获取投资组合失败: \(error)")
                    }
                },
                receiveValue: { [weak self] portfolio in
                    print("💰 从投资组合接口获取最新数据:")
                    print("💰   - 现金余额: $\(String(format: "%.2f", portfolio.cashBalance))")
                    print("💰   - 股票价值: $\(String(format: "%.2f", portfolio.stockValue))")
                    print("💰   - 总资产: $\(String(format: "%.2f", portfolio.totalValue))")
                    print("💰   - 持仓数量: \(portfolio.holdings.count)个")
                    
                    // 更新现金余额（来自真实的后端数据）
                    self?.availableCash = portfolio.cashBalance
                    print("💰 已更新可用现金: $\(String(format: "%.2f", portfolio.cashBalance))")
                    
                    // 查找当前游戏的持仓
                    let holding = portfolio.holdings.first { $0.gameId == game.id }
                    self?.currentHolding = holding?.quantity ?? 0
                    print("📊 当前游戏持仓: \(self?.currentHolding ?? 0)股")
                    
                    // 如果是卖出模式且没有持仓，重置为买入模式
                    if self?.tradingType == .sell && self?.currentHolding == 0 {
                        print("🔄 无持仓，切换为买入模式")
                        self?.tradingType = .buy
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 处理交易响应
    private func handleTransactionResponse(_ response: TransactionResponse) {
        isTransactionSuccessful = response.success
        
        if response.success {
            alertMessage = response.actualMessage
            
            // 更新本地数据
            if let newBalance = response.newBalance {
                availableCash = newBalance
            }
            
            // 更新持仓数量
            if tradingType == .buy {
                currentHolding += quantity
            } else {
                currentHolding -= quantity
            }
            
            // 重置数量
            quantity = 1
            
        } else {
            alertMessage = response.actualMessage
        }
        
        showAlert = true
    }
    
    /// 显示错误信息
    private func showError(_ message: String) {
        alertMessage = message
        isTransactionSuccessful = false
        showAlert = true
    }
    
    /// 获取并打印最新的投资组合信息
    private func logLatestPortfolio() {
        print("🔄 获取交易后最新投资组合...")
        
        networkManager.fetchPortfolio()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ 最新投资组合获取完成")
                    case .failure(let error):
                        print("❌ 最新投资组合获取失败: \(error)")
                    }
                },
                receiveValue: { portfolio in
                    print("🔄 ========== 交易后最新资产 ==========")
                    print("🔄 现金余额: $\(String(format: "%.2f", portfolio.cashBalance))")
                    print("🔄 股票价值: $\(String(format: "%.2f", portfolio.stockValue))")
                    print("🔄 总资产: $\(String(format: "%.2f", portfolio.totalValue))")
                    print("🔄 总盈亏: $\(String(format: "%.2f", portfolio.totalGainLoss))")
                    print("🔄 持仓数量: \(portfolio.holdings.count)个")
                    
                                         for (index, holding) in portfolio.holdings.enumerated() {
                         print("🔄 持仓\(index + 1): 游戏ID=\(holding.gameId), 股数=\(holding.quantity), 平均成本=$\(String(format: "%.2f", holding.averageCost)), 当前价值=$\(String(format: "%.2f", holding.totalValue))")
                     }
                    print("🔄 ====================================")
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - 扩展：交易类型切换逻辑
extension TradingViewModel {
    
    /// 当交易类型改变时的处理
    func didChangeTradingType() {
        // 重置数量为1
        quantity = 1
        
        // 如果切换到卖出但没有持仓，显示提示
        if tradingType == .sell && currentHolding == 0 {
            showError("您还没有持有这支股票")
            tradingType = .buy
        }
    }
}
