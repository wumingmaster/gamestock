//
//  UserService.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/3.
//

import Foundation
import Combine

class UserService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var portfolio: Portfolio?
    @Published var transactions: [Transaction] = []
    
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    init(networkManager: NetworkManager = NetworkManager()) {
        self.networkManager = networkManager
        // 模拟已登录用户
        self.mockLogin()
    }
    
    // MARK: - Authentication
    
    func getCurrentUser() -> AnyPublisher<User, Error> {
        return Future<User, Error> { promise in
            if let user = self.currentUser {
                promise(.success(user))
            } else {
                promise(.failure(NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func login(username: String, password: String) {
        // 这里应该调用实际的登录API
        // 现在使用模拟数据
        mockLogin()
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        portfolio = nil
        transactions = []
    }
    
    // MARK: - Portfolio
    
    func fetchPortfolio() {
        guard isLoggedIn else { return }
        
        // 模拟API调用
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.portfolio = Portfolio.sampleData
        }
    }
    
    // MARK: - Transactions
    
    func fetchTransactions() {
        guard isLoggedIn else { return }
        
        // 模拟API调用
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.transactions = Transaction.sampleData
        }
    }
    
    func buyStock(gameId: Int, gameName: String, quantity: Int, price: Double) -> Future<Bool, Error> {
        return Future { promise in
            // 这里应该调用实际的购买API
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 模拟成功
                let newTransaction = Transaction(
                    id: Int.random(in: 1000...9999),
                    gameId: gameId,
                    gameName: gameName,
                    type: .buy,
                    quantity: quantity,
                    price: price,
                    totalAmount: Double(quantity) * price,
                    timestamp: Date()
                )
                
                self.transactions.insert(newTransaction, at: 0)
                
                // 更新用户余额
                if let user = self.currentUser {
                    let newBalance = user.balance - (Double(quantity) * price)
                    self.currentUser = User(
                        id: user.id,
                        username: user.username,
                        email: user.email,
                        balance: newBalance,
                        createdAt: user.createdAt,
                        isActive: user.isActive
                    )
                }
                
                // 刷新投资组合
                self.fetchPortfolio()
                
                promise(.success(true))
            }
        }
    }
    
    func sellStock(gameId: Int, gameName: String, quantity: Int, price: Double) -> Future<Bool, Error> {
        return Future { promise in
            // 这里应该调用实际的卖出API
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 模拟成功
                let newTransaction = Transaction(
                    id: Int.random(in: 1000...9999),
                    gameId: gameId,
                    gameName: gameName,
                    type: .sell,
                    quantity: quantity,
                    price: price,
                    totalAmount: Double(quantity) * price,
                    timestamp: Date()
                )
                
                self.transactions.insert(newTransaction, at: 0)
                
                // 更新用户余额
                if let user = self.currentUser {
                    let newBalance = user.balance + (Double(quantity) * price)
                    self.currentUser = User(
                        id: user.id,
                        username: user.username,
                        email: user.email,
                        balance: newBalance,
                        createdAt: user.createdAt,
                        isActive: user.isActive
                    )
                }
                
                // 刷新投资组合
                self.fetchPortfolio()
                
                promise(.success(true))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func mockLogin() {
        // 模拟用户数据
        currentUser = User(
            id: 1,
            username: "游戏投资者",
            email: "investor@gamestock.com",
            balance: 10000.0,
            createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
            isActive: true
        )
        isLoggedIn = true
        
        // 获取投资组合和交易历史
        fetchPortfolio()
        fetchTransactions()
    }
}

 