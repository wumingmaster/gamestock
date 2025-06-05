//
//  MarketView.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import SwiftUI

// 临时GameIconView定义 - 解决编译问题
struct GameIconView: View {
    let game: Game
    let size: CGSize
    let cornerRadius: CGFloat
    
    @State private var currentUrlIndex = 0
    @State private var hasError = false
    
    init(game: Game, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 8) {
        self.game = game
        self.size = CGSize(width: width, height: height)
        self.cornerRadius = cornerRadius
    }
    
    private var fallbackUrls: [String] {
        // 使用Game模型的智能图标URL
        return [game.gameIconUrl]
    }
    
    private var currentUrl: String? {
        guard currentUrlIndex < fallbackUrls.count else { return nil }
        return fallbackUrls[currentUrlIndex]
    }
    
    var body: some View {
        Group {
            if let urlString = currentUrl, let url = URL(string: urlString), !hasError {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingPlaceholder
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill).frame(width: size.width, height: size.height).clipped()
                            .onAppear {
                                print("✅ 🛒 市场图标加载成功!")
                                print("   游戏: \(game.name)")
                                print("   URL: \(urlString)")
                            }
                    case .failure(let error):
                        Color.clear.onAppear { 
                            print("❌ 🛒 市场图标加载失败!")
                            print("   游戏: \(game.name)")
                            print("   URL: \(urlString)")
                            print("   错误: \(error.localizedDescription)")
                            tryNextUrl() 
                        }
                    @unknown default:
                        loadingPlaceholder
                    }
                }
            } else {
                finalPlaceholder
            }
        }
        .frame(width: size.width, height: size.height)
        .cornerRadius(cornerRadius)
    }
    
    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8))
    }
    
    private var finalPlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Image(systemName: "gamecontroller.fill").font(.system(size: min(size.width, size.height) * 0.4)).foregroundColor(.white))
    }
    
    private func tryNextUrl() {
        if currentUrlIndex < fallbackUrls.count - 1 {
            currentUrlIndex += 1
        } else {
            hasError = true
        }
    }
    
    static func small(game: Game) -> GameIconView {
        GameIconView(game: game, width: 50, height: 50, cornerRadius: 8)
    }
    
    static func medium(game: Game) -> GameIconView {
        GameIconView(game: game, width: 80, height: 80, cornerRadius: 12)
    }
    
    static func large(game: Game) -> GameIconView {
        GameIconView(game: game, width: 100, height: 100, cornerRadius: 16)
    }
}

struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()
    @State private var showingGameDetail = false
    @State private var selectedGame: Game?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 调试信息栏
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MarketView v0.0.1")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(8)
                        
                        Text("DEBUG: 游戏数量 \(viewModel.games.count)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text("加载状态: \(viewModel.isLoading ? "加载中" : "已完成")")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // 搜索和排序栏 - iPhone优化
                searchAndSortHeader
                
                // 游戏列表
                gamesList
            }
            .navigationTitle("股票市场")
            .refreshable {
                viewModel.refresh()
            }
        }
    }
    
    // MARK: - iPhone优化的搜索和排序栏
    private var searchAndSortHeader: some View {
        VStack(spacing: 10) {
            // 搜索框 - 为iPhone优化
            SearchBar(text: $viewModel.searchText)
            
            // 排序按钮 - 紧凑设计
            HStack {
                Text("排序")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    viewModel.showSortMenu.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.sortOption.icon)
                            .font(.caption)
                        Text(viewModel.sortOption.rawValue)
                            .font(.footnote)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                .confirmationDialog("排序方式", isPresented: $viewModel.showSortMenu, titleVisibility: .visible) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            viewModel.setSortOption(option)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - iPhone优化的游戏列表
    private var gamesList: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    viewModel.refresh()
                }
            } else {
                List(viewModel.filteredGames.indices, id: \.self) { index in
                    let game = viewModel.filteredGames[index]
                    GameRowView(game: game, rank: index + 1) {
                        print("\n=== 📱 市场界面股票点击 ===")
                        print("🎮 点击游戏: \(game.name)")
                        print("💵 当前价格: $\(game.currentPrice)")
                        print("🔗 iconUrl: \(game.iconUrl ?? "无")")
                        print("🎯 gameIconUrl: \(game.gameIconUrl)")
                        print("📊 排名: \(index + 1)")
                        print("=============================")
                        selectedGame = game
                        showingGameDetail = true
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .background(Color.white)
                }
                .listStyle(PlainListStyle())
                .scrollIndicators(.hidden)
            }
        }
        .sheet(item: $selectedGame) { game in
            TradingView(game: game)
        }
    }
}

// MARK: - iPhone优化的搜索框组件
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            TextField("搜索游戏...", text: $text)
                .font(.system(size: 16))
                .padding(.vertical, 10)
                .padding(.trailing, text.isEmpty ? 0 : 8)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

// MARK: - iPhone优化的游戏行视图
struct GameRowView: View {
    let game: Game
    let rank: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 紧凑的排名徽章
                RankBadge(rank: rank)
                
                // 游戏图标 - 智能加载
                GameIconView.small(game: game)
                
                VStack(alignment: .leading, spacing: 3) {
                    // 游戏名称 - iPhone优化字体
                    Text(game.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    // 好评信息行
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 11))
                        Text(game.reviewRatePercentage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text("\(formatNumber(game.positiveReviews))好评")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 2) {
                    // 股价 - iPhone优化大小
                    Text(game.formattedPrice)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(game.priceChangeColor)
                    
                    // 涨跌幅
                    Text("+2.34%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000.0)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - iPhone优化的排名徽章
struct RankBadge: View {
    let rank: Int
    
    var body: some View {
        Text("\(rank)")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(
                Circle()
                    .fill(rankColor)
            )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .orange
        case 2:
            return .gray
        case 3:
            return .brown
        case 4...10:
            return .blue
        default:
            return .secondary
        }
    }
}

// MARK: - iPhone优化的错误视图
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("网络错误")
                .font(.system(size: 18, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: onRetry) {
                Text("重试")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

// MARK: - 预览
struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
            .previewDevice("iPhone 15")
    }
}