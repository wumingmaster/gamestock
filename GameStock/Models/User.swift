//
//  User.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import Foundation
import SwiftUI

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: Int
    let username: String
    let email: String
    let balance: Double
    let createdAt: Date?
    let isActive: Bool
    
    var formattedBalance: String {
        return String(format: "$%.2f", balance)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case balance
        case createdAt = "created_at"
        case isActive = "is_active"
    }
}

// MARK: - Portfolio Response Model (匹配服务器返回格式)
struct PortfolioResponse: Codable {
    let portfolios: [ServerHolding]
    let summary: PortfolioSummary
    
    // 转换为客户端Portfolio格式
    var toClientPortfolio: Portfolio {
        let holdings = portfolios.map { serverHolding in
            Holding(
                id: serverHolding.id,
                gameId: serverHolding.gameId,
                gameName: serverHolding.gameName,
                quantity: serverHolding.shares,
                averageCost: serverHolding.avgBuyPrice,
                currentPrice: serverHolding.currentPrice,
                totalValue: serverHolding.totalValue,
                gainLoss: serverHolding.profitLoss,
                gainLossPercentage: serverHolding.profitLossPercent
            )
        }
        
        return Portfolio(
            totalValue: summary.totalAssets,
            cashBalance: summary.cashBalance,
            stockValue: summary.totalValue,
            totalGainLoss: summary.totalProfitLoss,
            holdings: holdings
        )
    }
}

// MARK: - Server Holding Model
struct ServerHolding: Codable {
    let id: Int
    let gameId: Int
    let gameName: String
    let shares: Int
    let avgBuyPrice: Double
    let currentPrice: Double
    let totalValue: Double
    let profitLoss: Double
    let profitLossPercent: Double
    let createdAt: String
    let updatedAt: String
    let userId: Int
    let gameSteamId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case gameName = "game_name"
        case shares
        case avgBuyPrice = "avg_buy_price"
        case currentPrice = "current_price"
        case totalValue = "total_value"
        case profitLoss = "profit_loss"
        case profitLossPercent = "profit_loss_percent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
        case gameSteamId = "game_steam_id"
    }
}

// MARK: - Portfolio Summary Model
struct PortfolioSummary: Codable {
    let cashBalance: Double
    let totalAssets: Double
    let totalCost: Double
    let totalProfitLoss: Double
    let totalProfitLossPercent: Double
    let totalStocks: Int
    let totalValue: Double
    
    enum CodingKeys: String, CodingKey {
        case cashBalance = "cash_balance"
        case totalAssets = "total_assets"
        case totalCost = "total_cost"
        case totalProfitLoss = "total_profit_loss"
        case totalProfitLossPercent = "total_profit_loss_percent"
        case totalStocks = "total_stocks"
        case totalValue = "total_value"
    }
}

// MARK: - Portfolio Model (客户端使用)
struct Portfolio: Codable {
    let totalValue: Double
    let cashBalance: Double
    let stockValue: Double
    let totalGainLoss: Double
    let holdings: [Holding]
    
    var formattedTotalValue: String {
        return String(format: "$%.2f", totalValue)
    }
    
    var formattedCashBalance: String {
        return String(format: "$%.2f", cashBalance)
    }
    
    var gainLossColor: Color {
        return totalGainLoss >= 0 ? .green : .red
    }
    
    enum CodingKeys: String, CodingKey {
        case totalValue = "total_value"
        case cashBalance = "cash_balance"
        case stockValue = "stock_value"
        case totalGainLoss = "total_gain_loss"
        case holdings
    }
}

// MARK: - Holding Model
struct Holding: Identifiable, Codable {
    let id: Int
    let gameId: Int
    let gameName: String
    let quantity: Int
    let averageCost: Double
    let currentPrice: Double
    let totalValue: Double
    let gainLoss: Double
    let gainLossPercentage: Double
    
    var formattedGainLoss: String {
        let sign = gainLoss >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", gainLoss))"
    }
    
    var formattedPercentage: String {
        let sign = gainLossPercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", gainLossPercentage))%"
    }
    
    var gainLossColor: Color {
        return gainLoss >= 0 ? .green : .red
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case gameName = "game_name"
        case quantity
        case averageCost = "average_cost"
        case currentPrice = "current_price"
        case totalValue = "total_value"
        case gainLoss = "gain_loss"
        case gainLossPercentage = "gain_loss_percentage"
    }
}

// MARK: - Transaction Model
struct Transaction: Identifiable, Codable {
    let id: Int
    let gameId: Int
    let gameName: String
    let type: TransactionType
    let quantity: Int
    let price: Double
    let totalAmount: Double
    let timestamp: Date
    
    var formattedAmount: String {
        return String(format: "$%.2f", totalAmount)
    }
    
    var typeColor: Color {
        switch type {
        case .buy:
            return .blue
        case .sell:
            return .orange
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case gameName = "game_name"
        case type
        case quantity
        case price
        case totalAmount = "total_amount"
        case timestamp
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case buy = "buy"
    case sell = "sell"
    
    var displayName: String {
        switch self {
        case .buy:
            return "买入"
        case .sell:
            return "卖出"
        }
    }
}

// MARK: - API Response Models

struct LoginResponse: Codable {
    let message: String
    let user: UserInfo
    
    // 为兼容性提供计算属性
    var id: Int { user.id }
    var username: String { user.username }
    var email: String { user.email }
    var balance: Double { user.balance }
}

struct UserInfo: Codable {
    let id: Int
    let username: String
    let email: String
    let balance: Double
    let isActive: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case balance
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct TransactionResponse: Codable {
    let message: String?
    let error: String?
    let userBalance: Double?
    let transaction: TransactionDetail?
    let portfolio: PortfolioDetail?
    
    // 计算属性以保持兼容性
    var success: Bool {
        // 如果有error字段，说明失败了
        if let _ = error {
            return false
        }
        // 如果有message字段，检查内容
        if let msg = message {
            return !msg.contains("失败") && !msg.contains("错误")
        }
        return false
    }
    
    var actualMessage: String {
        return message ?? error ?? "未知错误"
    }
    
    var newBalance: Double? {
        return userBalance
    }
    
    enum CodingKeys: String, CodingKey {
        case message
        case error
        case userBalance = "user_balance"
        case transaction
        case portfolio
    }
}

struct TransactionDetail: Codable {
    let id: Int
    let gameId: Int
    let shares: Int
    let price: Double
    let type: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case shares
        case price = "price_per_share"
        case type = "transaction_type"
        case timestamp = "created_at"
    }
}

struct PortfolioDetail: Codable {
    let id: Int
    let gameId: Int
    let shares: Int
    let avgBuyPrice: Double
    let currentPrice: Double
    let totalValue: Double
    let profitLoss: Double
    let profitLossPercent: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case shares
        case avgBuyPrice = "avg_buy_price"
        case currentPrice = "current_price"
        case totalValue = "total_value"
        case profitLoss = "profit_loss"
        case profitLossPercent = "profit_loss_percent"
    }
}

// MARK: - Sample Data
extension Portfolio {
    static let sampleData = Portfolio(
        totalValue: 15430.50,
        cashBalance: 5430.50,
        stockValue: 10000.00,
        totalGainLoss: 1430.50,
        holdings: [
            Holding(
                id: 1,
                gameId: 1,
                gameName: "Counter-Strike 2",
                quantity: 30,
                averageCost: 150.00,
                currentPrice: 168.05,
                totalValue: 5041.50,
                gainLoss: 541.50,
                gainLossPercentage: 12.04
            ),
            Holding(
                id: 2,
                gameId: 3,
                gameName: "Black Myth: Wukong",
                quantity: 25,
                averageCost: 180.00,
                currentPrice: 198.45,
                totalValue: 4961.25,
                gainLoss: 461.25,
                gainLossPercentage: 10.25
            )
        ]
    )
}

extension Transaction {
    static let sampleData: [Transaction] = [
        Transaction(
            id: 1,
            gameId: 1,
            gameName: "Counter-Strike 2",
            type: .buy,
            quantity: 10,
            price: 150.00,
            totalAmount: 1500.00,
            timestamp: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        ),
        Transaction(
            id: 2,
            gameId: 3,
            gameName: "Black Myth: Wukong",
            type: .buy,
            quantity: 15,
            price: 180.00,
            totalAmount: 2700.00,
            timestamp: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        ),
        Transaction(
            id: 3,
            gameId: 5,
            gameName: "Baldur's Gate 3",
            type: .sell,
            quantity: 5,
            price: 220.00,
            totalAmount: 1100.00,
            timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        ),
        Transaction(
            id: 4,
            gameId: 1,
            gameName: "Counter-Strike 2",
            type: .buy,
            quantity: 20,
            price: 158.50,
            totalAmount: 3170.00,
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )
    ]
} 