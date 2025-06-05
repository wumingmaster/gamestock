//
//  PortfolioViewModel.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class PortfolioViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var portfolio: Portfolio?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var performanceData: [PerformanceDataPoint] = []
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 今日收益
    var todayGainLoss: String {
        // 模拟今日收益计算
        let todayGain = Double.random(in: -500...500)
        let sign = todayGain >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", todayGain))"
    }
    
    /// 今日收益颜色
    var todayGainLossColor: Color {
        return todayGainLoss.hasPrefix("+") ? .green : .red
    }
    
    /// 总收益
    var totalGainLoss: String {
        guard let portfolio = portfolio else { return "$0.00" }
        let sign = portfolio.totalGainLoss >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", portfolio.totalGainLoss))"
    }
    
    /// 总收益百分比
    var totalGainLossPercentage: String {
        guard let portfolio = portfolio else { return "0.0%" }
        
        let initialInvestment = portfolio.totalValue - portfolio.totalGainLoss
        guard initialInvestment > 0 else { return "0.0%" }
        
        let percentage = (portfolio.totalGainLoss / initialInvestment) * 100
        let sign = percentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percentage))%"
    }
    
    // MARK: - Initialization
    init() {
        generateSamplePerformanceData()
    }
    
    // MARK: - Public Methods
    
    /// 加载投资组合数据
    func loadPortfolio() {
        isLoading = true
        errorMessage = nil
        
        networkManager.fetchPortfolio()
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    // 使用示例数据作为后备
                    self?.portfolio = Portfolio.sampleData
                }
            },
            receiveValue: { [weak self] (portfolio: Portfolio) in
                self?.portfolio = portfolio
            }
        )
        .store(in: &cancellables)
    }
    
    /// 刷新数据
    func refreshData() async {
        loadPortfolio()
        
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    /// 获取特定游戏的持仓
    func getHolding(for gameId: Int) -> Holding? {
        return portfolio?.holdings.first { $0.gameId == gameId }
    }
    
    // MARK: - Private Methods
    
    /// 生成示例收益数据
    private func generateSamplePerformanceData() {
        let calendar = Calendar.current
        let now = Date()
        
        performanceData = (0..<30).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else {
                return nil
            }
            
            // 生成模拟的收益数据，呈现波动趋势
            let baseValue = 10000.0
            let volatility = 500.0
            let trend = Double(30 - dayOffset) * 10 // 轻微上升趋势
            let randomVariation = Double.random(in: -volatility...volatility)
            let value = baseValue + trend + randomVariation
            
            return PerformanceDataPoint(
                date: date,
                value: value
            )
        }.reversed()
    }
}

// MARK: - 收益数据点模型
struct PerformanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - 网络错误处理扩展
extension PortfolioViewModel {
    
    /// 处理网络错误
    private func handleNetworkError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
            self?.isLoading = false
            
            // 使用示例数据作为后备
            self?.portfolio = Portfolio.sampleData
        }
    }
}

 