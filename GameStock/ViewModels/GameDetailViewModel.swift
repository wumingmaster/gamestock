//
//  GameDetailViewModel.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/3.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class GameDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var priceHistory: [PricePoint] = []
    @Published var priceChange: Double = 0.0
    @Published var priceChangePercent: Double = 0.0
    @Published var dayHigh: Double = 0.0
    @Published var dayLow: Double = 0.0
    @Published var marketRank: Int = 1
    @Published var formattedVolume: String = "0"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentGame: Game?
    private var currentTimeRange: TimeRange = .day
    
    // MARK: - Public Methods
    
    /// 加载游戏详情数据
    func loadGameDetail(_ game: Game) {
        currentGame = game
        loadPriceHistory(for: game, timeRange: .day)
        calculatePriceStatistics(for: game)
        loadMarketRank(for: game)
    }
    
    /// 刷新数据
    func refreshData(for game: Game) {
        loadGameDetail(game)
    }
    
    /// 更新时间范围
    func updateTimeRange(_ timeRange: TimeRange, for game: Game) {
        currentTimeRange = timeRange
        loadPriceHistory(for: game, timeRange: timeRange)
    }
    
    // MARK: - Private Methods
    
    /// 加载股价历史数据
    private func loadPriceHistory(for game: Game, timeRange: TimeRange) {
        isLoading = true
        errorMessage = nil
        
        // 在真实应用中，这里会从API获取历史数据
        // 目前使用模拟数据演示功能
        generateMockPriceHistory(for: game, timeRange: timeRange)
        
        isLoading = false
    }
    
    /// 生成模拟股价历史数据
    private func generateMockPriceHistory(for game: Game, timeRange: TimeRange) {
        let basePrice = game.currentPrice
        let pointCount = getPointCount(for: timeRange)
        let timeInterval = getTimeInterval(for: timeRange)
        
        var points: [PricePoint] = []
        let now = Date()
        
        for i in 0..<pointCount {
            let timestamp = now.addingTimeInterval(-timeInterval * Double(pointCount - i - 1))
            
            // 模拟价格波动 (基于正弦波和随机因素)
            let progress = Double(i) / Double(pointCount - 1)
            let sineWave = sin(progress * .pi * 4) * 0.1 // ±10%的正弦波动
            let randomFactor = Double.random(in: -0.05...0.05) // ±5%的随机波动
            let trendFactor = (progress - 0.5) * 0.1 // 整体趋势
            
            let totalVariation = sineWave + randomFactor + trendFactor
            let price = basePrice * (1 + totalVariation)
            
            points.append(PricePoint(timestamp: timestamp, price: max(price, 1.0)))
        }
        
        priceHistory = points
        updatePriceStatistics()
    }
    
    /// 计算价格统计数据
    private func calculatePriceStatistics(for game: Game) {
        let basePrice = game.currentPrice
        
        // 模拟24小时价格变化
        let yesterdayPrice = basePrice * Double.random(in: 0.95...1.05)
        priceChange = basePrice - yesterdayPrice
        priceChangePercent = (priceChange / yesterdayPrice) * 100
        
        // 模拟日高日低
        dayHigh = basePrice * Double.random(in: 1.02...1.08)
        dayLow = basePrice * Double.random(in: 0.92...0.98)
    }
    
    /// 更新价格统计
    private func updatePriceStatistics() {
        guard !priceHistory.isEmpty else { return }
        
        let prices = priceHistory.map { $0.price }
        dayHigh = prices.max() ?? 0.0
        dayLow = prices.min() ?? 0.0
        
        if priceHistory.count >= 2 {
            let oldPrice = priceHistory[0].price
            let newPrice = priceHistory.last!.price
            priceChange = newPrice - oldPrice
            priceChangePercent = (priceChange / oldPrice) * 100
        }
        
        // 模拟成交量
        let baseVolume = Int.random(in: 100...10000)
        formattedVolume = formatVolume(baseVolume)
    }
    
    /// 加载市场排名
    private func loadMarketRank(for game: Game) {
        // 在真实应用中，这里会从API获取排名数据
        // 目前基于价格模拟排名
        let priceRanking = Int(game.currentPrice / 10) + Int.random(in: 1...5)
        marketRank = max(1, min(priceRanking, 100))
    }
    
    /// 获取时间范围对应的数据点数量
    private func getPointCount(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .day: return 24  // 24小时，每小时一个点
        case .week: return 168 // 7天，每小时一个点
        case .month: return 30 // 30天，每天一个点
        case .year: return 52  // 52周，每周一个点
        }
    }
    
    /// 获取时间间隔（秒）
    private func getTimeInterval(for timeRange: TimeRange) -> TimeInterval {
        switch timeRange {
        case .day: return 3600    // 1小时
        case .week: return 3600   // 1小时
        case .month: return 86400 // 1天
        case .year: return 604800 // 1周
        }
    }
    
    /// 格式化成交量
    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000000 {
            return String(format: "%.1fM", Double(volume) / 1000000.0)
        } else if volume >= 1000 {
            return String(format: "%.1fK", Double(volume) / 1000.0)
        } else {
            return "\(volume)"
        }
    }
}

// MARK: - 价格数据点模型

struct PricePoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let price: Double
}

// MARK: - 扩展Game模型（GameDetailView专用）

extension Game {
    /// 用于详情视图的总评论数
    var detailTotalReviews: Int {
        return calculatedTotalReviews
    }
} 