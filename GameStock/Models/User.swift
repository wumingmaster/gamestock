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

// MARK: - Portfolio Model
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
    let id: Int
    let username: String
    let email: String
    let balance: Double
    let message: String?
}

struct TransactionResponse: Codable {
    let message: String
    let userBalance: Double
    let transaction: TransactionDetail?
    let portfolio: PortfolioDetail?
    
    // 计算属性以保持兼容性
    var success: Bool {
        return !message.contains("失败") && !message.contains("错误")
    }
    
    var newBalance: Double? {
        return userBalance
    }
    
    enum CodingKeys: String, CodingKey {
        case message
        case userBalance = "user_balance"
        case transaction
        case portfolio
    }
}

struct TransactionDetail: Codable {
    let id: Int
    let gameId: Int
    let gameName: String
    let transactionType: String
    let shares: Int
    let pricePerShare: Double
    let totalAmount: Double
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case gameName = "game_name"
        case transactionType = "transaction_type"
        case shares
        case pricePerShare = "price_per_share"
        case totalAmount = "total_amount"
        case createdAt = "created_at"
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