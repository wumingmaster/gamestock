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
    @Published var games: [Game] = []
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 今日收益
    var todayGainLoss: String {
        guard let portfolio = portfolio else { return "Ⓖ0.00" }
        var total: Double = 0
        for holding in portfolio.holdings {
            let current = holding.currentPrice
            if let yesterday = PriceHistoryManager.shared.yesterdayPrice(gameId: holding.gameId) {
                let gain = (current - yesterday) * Double(holding.quantity)
                total += gain
            }
        }
        let sign = total >= 0 ? "+" : ""
        return "\(sign)Ⓖ\(String(format: "%.2f", total))"
    }
    
    /// 今日收益颜色
    var todayGainLossColor: Color {
        return todayGainLoss.hasPrefix("+") ? .green : .red
    }
    
    /// 总收益
    var totalGainLoss: String {
        guard let portfolio = portfolio else { return "Ⓖ0.00" }
        let sign = portfolio.totalGainLoss >= 0 ? "+" : ""
        return "\(sign)Ⓖ\(String(format: "%.2f", portfolio.totalGainLoss))"
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
        print("💼 开始加载投资组合...")
        isLoading = true
        errorMessage = nil
        
        // 先确保用户已登录，然后获取投资组合
        networkManager.autoLoginTestUser()
            .flatMap { [weak self] _ -> AnyPublisher<Portfolio, NetworkError> in
                print("✅ 登录成功，开始获取投资组合...")
                guard let self = self else {
                    return Fail(error: NetworkError.networkError(NSError(domain: "PortfolioViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"])))
                        .eraseToAnyPublisher()
                }
                return self.networkManager.fetchPortfolio()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .finished:
                        print("🎉 投资组合加载完成")
                    case .failure(let error):
                        print("❌ 投资组合加载失败: \(error)")
                        self?.errorMessage = error.localizedDescription
                        // 使用示例数据作为后备
                        self?.portfolio = Portfolio.sampleData
                    }
                },
                receiveValue: { [weak self] (portfolio: Portfolio) in
                    print("📊 收到投资组合数据: \(portfolio.holdings.count)个持仓")
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
    
    /// 加载全量游戏列表
    func loadGames() {
        print("🎮 开始加载全量游戏列表...")
        networkManager.fetchGames()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        print("✅ 游戏列表加载完成")
                    case .failure(let error):
                        print("❌ 游戏列表加载失败: \(error)")
                        self?.games = []
                    }
                },
                receiveValue: { [weak self] games in
                    print("🎮 收到\(games.count)个游戏")
                    self?.games = games
                }
            )
            .store(in: &cancellables)
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

 