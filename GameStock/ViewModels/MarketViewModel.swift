//
//  MarketViewModel.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class MarketViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .price
    @Published var showSortMenu = false
    @Published var lastUpdateTime: Date?
    @Published var networkStatus: NetworkStatus = .idle
    @Published var followedGameIds: Set<Int> = []
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Constants
    private let autoRefreshInterval: TimeInterval = 60 // 60秒自动刷新
    let defaultFollowedGameIds: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20] // 示例ID，需替换为真实热门游戏ID
    
    // MARK: - Computed Properties
    var filteredGames: [Game] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return games.filter { followedGameIds.contains($0.id) }
        } else {
            let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            return games.filter {
                $0.name.localizedCaseInsensitiveContains(keyword) ||
                ($0.nameZh?.localizedCaseInsensitiveContains(keyword) ?? false)
            }
        }
    }
    
    var formattedLastUpdateTime: String {
        guard let lastUpdateTime = lastUpdateTime else {
            return "从未更新"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "最后更新: \(formatter.string(from: lastUpdateTime))"
    }
    
    // MARK: - 初始化
    init() {
        setupAutoLogin()
        setupAutoRefresh()
        loadFollowedGames()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// 加载游戏列表
    func loadGames() {
        guard networkStatus != .loading else { return }
        
        isLoading = true
        errorMessage = nil
        networkStatus = .loading
        
        networkManager.fetchGames()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    switch completion {
                    case .finished:
                        self?.networkStatus = .success
                        self?.lastUpdateTime = Date()
                        self?.errorMessage = nil
                        print("✅ 游戏数据加载成功")
                        
                    case .failure(let error):
                        self?.networkStatus = .failed
                        self?.handleNetworkError(error)
                    }
                },
                receiveValue: { [weak self] games in
                    print("📦 收到 \(games.count) 个游戏数据")
                    self?.games = games
                }
            )
            .store(in: &cancellables)
    }
    
    /// 刷新数据
    func refresh() {
        print("🔄 手动刷新游戏数据")
        loadGames()
    }
    
    /// 搜索游戏
    func searchGames(query: String) {
        searchText = query
    }
    
    /// 设置排序选项
    func setSortOption(_ option: SortOption) {
        sortOption = option
        showSortMenu = false
    }
    
    /// 清除错误状态
    func clearError() {
        errorMessage = nil
        networkStatus = .idle
    }
    
    /// 重试加载
    func retryLoading() {
        print("🔄 重试加载游戏数据")
        loadGames()
    }
    
    /// 计算某只游戏的今日涨跌幅百分比
    func priceChangePercent(for game: Game) -> Double? {
        guard let yesterdayPrice = PriceHistoryManager.shared.yesterdayPrice(gameId: game.id), yesterdayPrice > 0 else { return nil }
        let change = (game.currentPrice - yesterdayPrice) / yesterdayPrice * 100
        return change
    }
    
    func toggleFollow(game: Game) {
        if followedGameIds.contains(game.id) {
            followedGameIds.remove(game.id)
        } else {
            followedGameIds.insert(game.id)
        }
        saveFollowedGames()
    }
    
    func saveFollowedGames() {
        UserDefaults.standard.set(Array(followedGameIds), forKey: "followedGameIds")
    }
    
    func loadFollowedGames() {
        if let ids = UserDefaults.standard.array(forKey: "followedGameIds") as? [Int] {
            followedGameIds = Set(ids)
        } else {
            // 首次启动，写入默认关注
            followedGameIds = Set(defaultFollowedGameIds)
            saveFollowedGames()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAutoLogin() {
        print("🔐 [MarketViewModel] 设置自动登录...")
        print("🔐 [MarketViewModel] NetworkManager状态: \(networkManager)")
        
        // 先尝试自动登录，然后加载游戏数据
        print("🔐 [MarketViewModel] 开始调用autoLoginTestUser...")
        
        networkManager.autoLoginTestUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    print("🔐 [MarketViewModel] 登录完成回调触发")
                    switch completion {
                    case .finished:
                        print("✅ [MarketViewModel] 自动登录成功")
                        // 登录成功后加载游戏数据
                        self?.loadGames()
                        
                    case .failure(let error):
                        print("❌ [MarketViewModel] 自动登录失败: \(error)")
                        print("❌ [MarketViewModel] 错误详情: \(error.localizedDescription)")
                        // 即使登录失败也尝试加载游戏数据（游戏列表不需要登录）
                        self?.loadGames()
                    }
                },
                receiveValue: { response in
                    print("🎉 [MarketViewModel] 登录响应: \(response)")
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 只有在不是加载状态且没有搜索时才自动刷新
            if self.networkStatus != .loading && self.searchText.isEmpty {
                print("⏰ 自动刷新游戏数据")
                self.loadGames()
            }
        }
    }
    
    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case .networkError(let underlyingError):
            if let urlError = underlyingError as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    self.errorMessage = "网络连接不可用，请检查网络设置"
                case .timedOut:
                    self.errorMessage = "网络请求超时，请稍后重试"
                case .cannotConnectToHost:
                    self.errorMessage = "无法连接到服务器，请稍后重试"
                default:
                    self.errorMessage = "网络错误：\(urlError.localizedDescription)"
                }
            } else {
                self.errorMessage = "网络错误：\(underlyingError.localizedDescription)"
            }
            
        case .decodingError:
            self.errorMessage = "数据解析错误，请稍后重试"
            
        case .invalidURL:
            self.errorMessage = "无效的服务器地址"
            
        case .encodingError:
            self.errorMessage = "数据编码错误"
            
        case .serverError(let message):
            self.errorMessage = "服务器错误：\(message)"
        }
        
        // 网络失败时使用示例数据
        if games.isEmpty {
            games = Game.sampleGames
            print("⚠️ 网络请求失败，使用示例数据: \(errorMessage ?? "未知错误")")
        }
    }
    
    private func sortedGames(_ games: [Game]) -> [Game] {
        switch sortOption {
        case .name:
            return games.sorted { $0.name < $1.name }
        case .price:
            return games.sorted { $0.currentPrice > $1.currentPrice }
        case .reviewRate:
            return games.sorted { $0.reviewRate > $1.reviewRate }
        case .positiveReviews:
            return games.sorted { $0.positiveReviews > $1.positiveReviews }
        }
    }
}

// MARK: - 网络状态枚举

enum NetworkStatus {
    case idle       // 空闲
    case loading    // 加载中
    case success    // 成功
    case failed     // 失败
    
    var description: String {
        switch self {
        case .idle:
            return "空闲"
        case .loading:
            return "加载中"
        case .success:
            return "成功"
        case .failed:
            return "失败"
        }
    }
}

// MARK: - 排序选项

enum SortOption: String, CaseIterable {
    case name = "名称"
    case price = "股价"
    case reviewRate = "好评率"
    case positiveReviews = "好评数"
    
    var icon: String {
        switch self {
        case .name:
            return "textformat.abc"
        case .price:
            return "dollarsign.circle"
        case .reviewRate:
            return "star.fill"
        case .positiveReviews:
            return "hand.thumbsup.fill"
        }
    }
} 