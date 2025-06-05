//
//  MarketView.swift
//  GameStock iOS
//
//  市场页面 - 显示股票游戏列表
//

import SwiftUI

struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()
    @State private var showingGameDetail = false
    @State private var selectedGame: Game?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索和排序栏
                searchAndSortHeader
                
                // 游戏列表
                gamesList
            }
            .navigationTitle("股票市场")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
        }
    }
    
    // MARK: - 搜索和排序栏
    private var searchAndSortHeader: some View {
        VStack(spacing: 12) {
            // 搜索框
            SearchBar(text: $viewModel.searchText)
            
            // 排序按钮
            HStack {
                Text("排序方式:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    viewModel.showSortMenu.toggle()
                }) {
                    HStack {
                        Image(systemName: viewModel.sortOption.icon)
                        Text(viewModel.sortOption.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }
                .actionSheet(isPresented: $viewModel.showSortMenu) {
                    ActionSheet(
                        title: Text("排序方式"),
                        buttons: SortOption.allCases.map { option in
                            .default(Text(option.rawValue)) {
                                viewModel.setSortOption(option)
                            }
                        } + [.cancel()]
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.top)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 游戏列表
    private var gamesList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    viewModel.refresh()
                }
            } else {
                List(viewModel.filteredGames) { game in
                    GameRowView(game: game) {
                        selectedGame = game
                        showingGameDetail = true
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(item: $selectedGame) { game in
            GameDetailView(game: game)
        }
    }
}

// MARK: - 搜索框组件
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索游戏...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button("清除") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 游戏行视图
struct GameRowView: View {
    let game: Game
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 排名徽章
                RankBadge(rank: getRank(for: game))
                
                VStack(alignment: .leading, spacing: 4) {
                    // 游戏名称
                    Text(game.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // 好评率
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(game.reviewRatePercentage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // 好评数
                        Text("\(formatNumber(game.positiveReviews)) 好评")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // 股价
                    Text(game.formattedPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(game.priceChangeColor)
                    
                    // 价格变化 (暂时显示静态)
                    Text("+2.34%")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getRank(for game: Game) -> Int {
        // 这里应该根据实际排名逻辑计算
        return 1
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - 排名徽章
struct RankBadge: View {
    let rank: Int
    
    var body: some View {
        Text("\(rank)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(rankColor)
            )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .orange // 金色
        case 2:
            return .gray   // 银色
        case 3:
            return .brown  // 铜色
        default:
            return .blue
        }
    }
}

// MARK: - 错误视图
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("出错了")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重试", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 游戏详情视图（占位符）
struct GameDetailView: View {
    let game: Game
    
    var body: some View {
        NavigationView {
            VStack {
                Text("游戏详情")
                    .font(.title)
                Text(game.name)
                    .font(.headline)
                Text(game.formattedPrice)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .padding()
            .navigationTitle(game.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("关闭") {
                // 关闭详情页
            })
        }
    }
}

// MARK: - 预览
struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
    }
} 