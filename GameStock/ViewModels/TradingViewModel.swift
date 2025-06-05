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
    
    // 用户数据
    @Published var availableCash: Double = 10000.0
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
        guard let game = game else { return false }
        
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
            showError("交易条件不满足")
            return
        }
        
        isLoading = true
        
        // 在交易前先确保用户已登录
        print("🔐 开始交易流程，先确保用户已登录...")
        
        networkManager.autoLoginTestUser()
            .flatMap { [weak self] _ -> AnyPublisher<TransactionResponse, NetworkError> in
                print("✅ 登录成功，开始执行交易...")
                
                guard let self = self, let game = self.game else {
                    return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
                }
                
                if self.tradingType == .buy {
                    return self.networkManager.buyStock(gameId: game.id, quantity: self.quantity)
                } else {
                    return self.networkManager.sellStock(gameId: game.id, quantity: self.quantity)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if self?.tradingType == .buy {
                            self?.showError("买入失败: \(error.localizedDescription)")
                        } else {
                            self?.showError("卖出失败: \(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleTransactionResponse(response)
                }
            )
            .store(in: &cancellables)
        
        // 原始的直接交易代码已移动到上面的flatMap中
        /*
        if tradingType == .buy {
            networkManager.buyStock(gameId: game.id, quantity: quantity)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.showError("买入失败: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { [weak self] response in
                        self?.handleTransactionResponse(response)
                    }
                )
                .store(in: &cancellables)
        } else {
            networkManager.sellStock(gameId: game.id, quantity: quantity)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.showError("卖出失败: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { [weak self] response in
                        self?.handleTransactionResponse(response)
                    }
                )
                .store(in: &cancellables)
        }
        */
    }
    
    // MARK: - Private Methods
    
    /// 加载用户数据
    private func loadUserData() {
        // 加载用户余额
        userService.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // 如果获取用户数据失败，使用默认值
                        print("获取用户数据失败，使用默认值")
                    }
                },
                receiveValue: { [weak self] (user: User) in
                    self?.availableCash = user.balance
                }
            )
            .store(in: &cancellables)
        
        // 加载当前持仓
        guard let game = game else { return }
        
        networkManager.fetchPortfolio()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        print("获取投资组合失败")
                    }
                },
                receiveValue: { [weak self] portfolio in
                    // 查找当前游戏的持仓
                    let holding = portfolio.holdings.first { $0.gameId == game.id }
                    self?.currentHolding = holding?.quantity ?? 0
                    
                    // 如果是卖出模式且没有持仓，重置为买入模式
                    if self?.tradingType == .sell && self?.currentHolding == 0 {
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
            alertMessage = response.message
            
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
            alertMessage = response.message
        }
        
        showAlert = true
    }
    
    /// 显示错误信息
    private func showError(_ message: String) {
        alertMessage = message
        isTransactionSuccessful = false
        showAlert = true
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
