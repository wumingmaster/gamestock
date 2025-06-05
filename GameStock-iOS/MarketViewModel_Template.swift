//
//  MarketViewModel.swift
//  GameStock iOS
//
//  市场视图模型 - 管理游戏列表和股票市场数据
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
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredGames: [Game] {
        let filtered = searchText.isEmpty ? games : games.filter { game in
            game.name.localizedCaseInsensitiveContains(searchText)
        }
        
        return sortedGames(filtered)
    }
    
    // MARK: - 初始化
    init() {
        loadGames()
    }
    
    // MARK: - Public Methods
    
    /// 加载游戏列表
    func loadGames() {
        isLoading = true
        errorMessage = nil
        
        networkManager.fetchGames()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] games in
                    self?.games = games
                }
            )
            .store(in: &cancellables)
    }
    
    /// 刷新数据
    func refresh() {
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
    
    // MARK: - Private Methods
    
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