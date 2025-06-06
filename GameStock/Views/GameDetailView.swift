//
//  GameDetailView.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/3.
//

import SwiftUI
import Charts

// 临时GameIconView定义 - 解决编译问题
struct DetailGameIconView: View {
    let game: Game
    let size: CGSize
    let cornerRadius: CGFloat
    
    init(game: Game, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 16) {
        self.game = game
        self.size = CGSize(width: width, height: height)
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        AsyncImage(url: URL(string: game.gameIconUrl)) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8))
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill).frame(width: size.width, height: size.height).clipped()
            case .failure(_):
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Image(systemName: "gamecontroller.fill").font(.system(size: min(size.width, size.height) * 0.4)).foregroundColor(.white))
            @unknown default:
                RoundedRectangle(cornerRadius: cornerRadius).fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: size.width, height: size.height)
        .cornerRadius(cornerRadius)
    }
    
    static func large(game: Game) -> DetailGameIconView {
        DetailGameIconView(game: game, width: 100, height: 100, cornerRadius: 16)
    }
}

struct GameDetailView: View {
    let game: Game
    @StateObject private var tradingViewModel = TradingViewModel()
    @StateObject private var detailViewModel = GameDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showTradingSheet = false
    @State private var selectedTimeRange: TimeRange = .day
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 游戏头部信息
                    gameHeaderSection
                    
                    // 股价信息卡片
                    priceInfoCard
                    
                    // 股价走势图表
                    priceChartSection
                    
                    // 游戏详细统计
                    gameStatsSection
                    
                    // 交易操作区域
                    tradingActionsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("股票详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        detailViewModel.refreshData(for: game)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            detailViewModel.loadGameDetail(game)
        }
        .sheet(isPresented: $showTradingSheet) {
            TradingView(game: game)
        }
    }
    
    // MARK: - 游戏头部信息
    private var gameHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                // 游戏图标 - 智能加载
                DetailGameIconView.large(game: game)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(game.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(3)
                    
                    Text("Steam ID: \(game.steamId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(String(format: "%.1f%% 好评", game.reviewRate * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - 股价信息卡片
    private var priceInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前股价")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(game.formattedPrice)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: detailViewModel.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(detailViewModel.priceChange >= 0 ? .green : .red)
                            .font(.caption)
                        
                        Text("\(detailViewModel.priceChange >= 0 ? "+" : "")\(detailViewModel.priceChange, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(detailViewModel.priceChange >= 0 ? .green : .red)
                    }
                    
                    Text("\(detailViewModel.priceChangePercent >= 0 ? "+" : "")\(detailViewModel.priceChangePercent, specifier: "%.2f")%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 市场数据
            HStack(spacing: 20) {
                MarketDataItem(title: "24小时高", value: String(format: "%.2f", detailViewModel.dayHigh))
                MarketDataItem(title: "24小时低", value: String(format: "%.2f", detailViewModel.dayLow))
                MarketDataItem(title: "成交量", value: detailViewModel.formattedVolume)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - 股价走势图表
    private var priceChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("股价走势")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 时间范围选择器
                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // 图表区域
            Chart(detailViewModel.priceHistory) { point in
                LineMark(
                    x: .value("时间", point.timestamp),
                    y: .value("价格", point.price)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("时间", point.timestamp),
                    y: .value("价格", point.price)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel() {
                        if let price = value.as(Double.self) {
                            Text("Ⓖ\(price, specifier: "%.0f")")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel() {
                        if let date = value.as(Date.self) {
                            Text(formatChartDate(date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .onChange(of: selectedTimeRange) { newRange in
            detailViewModel.updateTimeRange(newRange, for: game)
        }
    }
    
    // MARK: - 游戏详细统计
    private var gameStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("游戏统计")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatsCard(
                    title: "好评数",
                    value: game.positiveReviews.formatted(),
                    icon: "hand.thumbsup.fill",
                    color: .green
                )
                
                StatsCard(
                    title: "总评论数",
                    value: game.detailTotalReviews.formatted(),
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .blue
                )
                
                StatsCard(
                    title: "好评率",
                    value: String(format: "%.1f%%", game.reviewRate * 100),
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatsCard(
                    title: "市场排名",
                    value: "#\(detailViewModel.marketRank)",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - 交易操作区域
    private var tradingActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("可用资金")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Ⓖ\(tradingViewModel.availableCash, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("持有数量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(tradingViewModel.currentHolding)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            HStack(spacing: 12) {
                // 买入按钮
                Button(action: {
                    tradingViewModel.tradingType = .buy
                    showTradingSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("买入")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(12)
                }
                
                // 卖出按钮
                Button(action: {
                    tradingViewModel.tradingType = .sell
                    showTradingSheet = true
                }) {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                        Text("卖出")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(tradingViewModel.currentHolding == 0)
                .opacity(tradingViewModel.currentHolding == 0 ? 0.6 : 1.0)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - 辅助方法
    private func formatChartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedTimeRange {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "MM/dd"
        case .month:
            formatter.dateFormat = "MM/dd"
        case .year:
            formatter.dateFormat = "MM/yy"
        }
        return formatter.string(from: date)
    }
}

// MARK: - 辅助视图组件

struct MarketDataItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 时间范围枚举

enum TimeRange: CaseIterable {
    case day, week, month, year
    
    var displayName: String {
        switch self {
        case .day: return "1天"
        case .week: return "1周"
        case .month: return "1月"
        case .year: return "1年"
        }
    }
}

// MARK: - 预览

struct GameDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GameDetailView(game: Game.sampleGames[0])
    }
} 