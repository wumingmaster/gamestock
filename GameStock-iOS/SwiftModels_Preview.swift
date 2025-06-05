//
//  SwiftModels_Preview.swift
//  GameStock iOS
//
//  这是iOS应用数据模型的预览文件
//  创建Xcode项目后将这些模型添加到项目中
//

import Foundation
import SwiftUI

// MARK: - Game Model
struct Game: Identifiable, Codable {
    let id: Int
    let name: String
    let steamId: String
    let currentPrice: Double
    let positiveReviews: Int
    let reviewRate: Double
    let salesCount: Int
    let lastUpdated: Date?
    
    // 计算属性
    var formattedPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    var reviewRatePercentage: String {
        return String(format: "%.1f%%", reviewRate * 100)
    }
    
    var priceChangeColor: Color {
        // 这里可以添加价格变化逻辑
        return currentPrice > 100 ? .green : .red
    }
    
    // CodingKeys for API mapping
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case steamId = "steam_id"
        case currentPrice = "current_price"
        case positiveReviews = "positive_reviews"
        case reviewRate = "review_rate"
        case salesCount = "sales_count"
        case lastUpdated = "last_updated"
    }
}

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
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

struct LoginResponse: Codable {
    let user: User
    let token: String? // 未来JWT实现
}

struct ErrorResponse: Codable {
    let error: String
    let message: String
}

// MARK: - Sample Data for Preview
extension Game {
    static let sampleData = [
        Game(
            id: 1,
            name: "Counter-Strike 2",
            steamId: "730",
            currentPrice: 168.05,
            positiveReviews: 400000,
            reviewRate: 0.8,
            salesCount: 50000000,
            lastUpdated: Date()
        ),
        Game(
            id: 2,
            name: "Dota 2",
            steamId: "570",
            currentPrice: 196.14,
            positiveReviews: 350000,
            reviewRate: 0.818,
            salesCount: 1000000,
            lastUpdated: Date()
        ),
        Game(
            id: 3,
            name: "Black Myth: Wukong",
            steamId: "2358720",
            currentPrice: 198.45,
            positiveReviews: 805000,
            reviewRate: 0.965,
            salesCount: 20000000,
            lastUpdated: Date()
        )
    ]
}

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