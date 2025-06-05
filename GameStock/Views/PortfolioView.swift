//
//  PortfolioView.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import SwiftUI
import Charts

// 临时GameIconView定义 - 解决编译问题
struct PortfolioGameIconView: View {
    let game: Game
    let size: CGSize
    let cornerRadius: CGFloat
    
    init(game: Game, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 8) {
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
    
    static func small(game: Game) -> PortfolioGameIconView {
        PortfolioGameIconView(game: game, width: 50, height: 50, cornerRadius: 8)
    }
}

struct PortfolioView: View {
    @StateObject private var viewModel = PortfolioViewModel()
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 总览卡片
                    portfolioOverviewCard
                    
                    // 分段控制器
                    segmentedControl
                    
                    // 内容区域
                    if selectedSegment == 0 {
                        holdingsSection
                    } else {
                        performanceSection
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("投资组合")
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            viewModel.loadPortfolio()
        }
    }
    
    // MARK: - 投资组合总览卡片
    private var portfolioOverviewCard: some View {
        VStack(spacing: 20) {
            // 总资产
            VStack(spacing: 8) {
                Text("总资产")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(viewModel.portfolio?.formattedTotalValue ?? "$0.00")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // 收益信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日收益")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(viewModel.todayGainLoss)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.todayGainLossColor)
                        
                        Image(systemName: viewModel.todayGainLoss.hasPrefix("+") ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .foregroundColor(viewModel.todayGainLossColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("总收益")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(viewModel.totalGainLoss)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.portfolio?.gainLossColor ?? .primary)
                        
                        Text(viewModel.totalGainLossPercentage)
                            .font(.caption)
                            .foregroundColor(viewModel.portfolio?.gainLossColor ?? .primary)
                    }
                }
            }
            
            // 资产分布
            HStack(spacing: 20) {
                AssetItem(
                    title: "现金",
                    amount: viewModel.portfolio?.formattedCashBalance ?? "$0.00",
                    color: .blue
                )
                
                AssetItem(
                    title: "股票",
                    amount: String(format: "$%.2f", viewModel.portfolio?.stockValue ?? 0),
                    color: .green
                )
                
                AssetItem(
                    title: "持仓",
                    amount: "\(viewModel.portfolio?.holdings.count ?? 0)支",
                    color: .orange
                )
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 分段控制器
    private var segmentedControl: some View {
        Picker("Portfolio Segments", selection: $selectedSegment) {
            Text("持仓").tag(0)
            Text("分析").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    // MARK: - 持仓部分
    private var holdingsSection: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("我的持仓")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    viewModel.loadPortfolio()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            
            // 持仓列表
            if let holdings = viewModel.portfolio?.holdings, !holdings.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(holdings) { holding in
                        HoldingCard(holding: holding)
                            .onTapGesture {
                                // 这里可以添加跳转到交易页面的逻辑
                            }
                    }
                }
            } else {
                EmptyStateView(
                    icon: "briefcase",
                    title: "暂无持仓",
                    subtitle: "去市场页面买入您的第一支游戏股票吧！"
                )
                .padding(.vertical, 40)
            }
        }
    }
    
    // MARK: - 分析部分
    private var performanceSection: some View {
        VStack(spacing: 20) {
            // 收益趋势图
            VStack(alignment: .leading, spacing: 12) {
                Text("收益趋势")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if #available(iOS 16.0, *) {
                    Chart(viewModel.performanceData) { item in
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("收益", item.value)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 200)
                    .chartYScale(domain: .automatic)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                    .chartYAxis {
                        AxisMarks(format: .currency(code: "USD"))
                    }
                } else {
                    // iOS 16以下版本的备用方案
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                Text("收益趋势图")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
            }
            .padding(20)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            
            // 持仓分布
            VStack(alignment: .leading, spacing: 12) {
                Text("持仓分布")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let holdings = viewModel.portfolio?.holdings, !holdings.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(holdings.prefix(5)) { holding in
                            HStack {
                                Circle()
                                    .fill(Color.random)
                                    .frame(width: 12, height: 12)
                                
                                Text(holding.gameName)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(Int(holding.totalValue / (viewModel.portfolio?.stockValue ?? 1) * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Text("暂无持仓数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
            .padding(20)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
        }
    }
}

// MARK: - 资产项目组件
struct AssetItem: View {
    let title: String
    let amount: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .fill(color)
                        .frame(width: 16, height: 16)
                )
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(amount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 持仓卡片组件
struct HoldingCard: View {
    let holding: Holding
    
    var body: some View {
        HStack(spacing: 16) {
            // 游戏图标 - 智能加载
                                    PortfolioGameIconView.small(game: Game.sampleGames.first { $0.steamId == String(holding.gameId) } ?? Game.sampleGames[0])
            
            VStack(alignment: .leading, spacing: 4) {
                Text(holding.gameName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(holding.quantity) 股 · $\(String(format: "%.2f", holding.averageCost))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", holding.totalValue))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Text(holding.formattedGainLoss)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(holding.gainLossColor)
                    
                    Text("(\(holding.formattedPercentage))")
                        .font(.caption)
                        .foregroundColor(holding.gainLossColor)
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.6))
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - 颜色扩展
extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

// MARK: - 预览
struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
    }
} 