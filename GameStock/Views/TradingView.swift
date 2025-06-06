//
//  TradingView.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import SwiftUI

// 临时GameIconView定义 - 解决编译问题
struct TradingGameIconView: View {
    let game: Game
    let size: CGSize
    let cornerRadius: CGFloat
    @State private var imageURL: URL?
    @State private var retryCount = 0
    @State private var forceRefresh = 0
    
    init(game: Game, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 12) {
        self.game = game
        self.size = CGSize(width: width, height: height)
        self.cornerRadius = cornerRadius
        print("🔨 TradingGameIconView.init() - 组件创建: \(game.name)")
    }
    
    var body: some View {
        let _ = print("🔥🔥🔥 TradingGameIconView.body 开始渲染: \(game.name)")
        let _ = print("🔥🔥🔥 imageURL: \(imageURL?.absoluteString ?? "nil")")
        
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        VStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.6)
                            Text("加载中")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    )
                    .onAppear {
                        print("⏳ 图标开始加载: \(game.name)")
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .onAppear {
                        print("✅ 🖼️ 图标加载成功!")
                        print("   游戏: \(game.name)")
                        print("   URL: \(imageURL?.absoluteString ?? "无")")
                        print("   重试次数: \(retryCount)")
                    }
            case .failure(let error):
                Button(action: {
                    print("👆 点击失败图标重试: \(game.name)")
                    retryImageLoad()
                }) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(colors: [Color.red.opacity(0.6), Color.orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: retryCount > 0 ? "exclamationmark.triangle.fill" : "gamecontroller.fill")
                                    .font(.system(size: min(size.width, size.height) * 0.3))
                                    .foregroundColor(.white)
                                Text("点击重试 \(retryCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        print("❌ 🖼️ 图标加载失败!")
                        print("   游戏: \(game.name)")
                        print("   错误: \(error.localizedDescription)")
                        print("   尝试的URL: \(imageURL?.absoluteString ?? "无")")
                        print("   gameIconUrl: \(game.gameIconUrl)")
                        print("   重试次数: \(retryCount)")
                        
                        // 测试URL是否可达
                        testUrlReachability()
                        
                        // 自动重试一次
                        if retryCount == 0 {
                            print("🔄 系统自动重试中...")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                retryImageLoad()
                            }
                        }
                    }
            @unknown default:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.system(size: min(size.width, size.height) * 0.4))
                            .foregroundColor(.white)
                    )
                    .onAppear {
                        print("❓ 未知图标状态: \(game.name)")
                    }
            }
        }
        .frame(width: size.width, height: size.height)
        .cornerRadius(cornerRadius)
        .onAppear {
            print("\n=== 🖼️ 图标组件初始化 ===")
            print("🎮 游戏: \(game.name)")
            print("📱 iconUrl字段: \(game.iconUrl ?? "nil")")
            print("🎯 gameIconUrl计算值: \(game.gameIconUrl)")
            print("📏 尺寸: \(size.width)x\(size.height)")
            print("==============================")
            setupImageURL()
        }
        .onAppear {
            print("🎯 AsyncImage容器出现: \(game.name)")
        }
    }
    
    private func setupImageURL() {
        let urlString = "\(game.gameIconUrl)?v=\(forceRefresh)"
        imageURL = URL(string: urlString)
        retryCount = 0
        print("🔧 📡 设置图标URL:")
        print("   完整URL: \(urlString)")
        print("   强制刷新版本: \(forceRefresh)")
    }
    
    private func retryImageLoad() {
        retryCount += 1
        forceRefresh += 1
        print("\n=== 👆 手动重试触发 ===")
        print("🎮 游戏: \(game.name)")
        print("🔢 重试次数: \(retryCount)")
        print("📡 强制刷新版本: \(forceRefresh)")
        
        // 强制刷新URL来触发重新加载，添加时间戳避免缓存
        imageURL = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let urlString = "\(game.gameIconUrl)?v=\(forceRefresh)&t=\(Date().timeIntervalSince1970)"
            imageURL = URL(string: urlString)
            print("🔧 重试URL: \(urlString)")
            print("========================")
        }
    }
    
    private func testUrlReachability() {
        // 简单的URL可达性测试
        guard let url = URL(string: game.gameIconUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 URL可达性测试: \(game.name) - 状态码: \(httpResponse.statusCode)")
                } else if let error = error {
                    print("🌐 URL可达性测试失败: \(game.name) - 错误: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    static func medium(game: Game) -> TradingGameIconView {
        print("🏭 TradingGameIconView.medium() 静态方法被调用: \(game.name)")
        return TradingGameIconView(game: game, width: 80, height: 80, cornerRadius: 12)
    }
}

struct TradingView: View {
    let game: Game
    @StateObject private var viewModel = TradingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 版本号显示
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
//                            Text("TradingView v0.0.1")
//                                .font(.caption)
//                                .fontWeight(.bold)
//                                .foregroundColor(.white)
//                                .padding(.horizontal, 8)
//                                .padding(.vertical, 4)
//                                .background(Color.purple)
//                                .cornerRadius(8)
//                            
//                            Text("DEBUG: 游戏=\(game.name)")
//                                .font(.caption2)
//                                .foregroundColor(.purple)
//                            
//                            Text("DEBUG: 价格=$\(game.currentPrice, specifier: "%.2f")")
//                                .font(.caption2)
//                                .foregroundColor(.purple)
                        }
                        Spacer()
                    }
                    
                    // 游戏信息卡片
                    gameInfoCard
                    
                    // 用户资产信息卡片
                    userAssetCard
                    
                    // 交易选择
                    tradingTypeSelector
                    
                    // 数量选择
                    quantitySelector
                    
                    // 交易总额显示
                    totalAmountCard
                    
                    // 交易按钮
                    tradingButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("交易 \(game.name)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                }
            )
        }
        .onAppear {
            print("\n=== 🚀 交易界面打开 ===")
            print("💰 TradingView.onAppear() - 交易页面已显示")
            print("🎮 游戏名称: \(game.name)")
            print("💵 游戏价格: $\(game.currentPrice)")
            print("⭐ 好评数: \(game.positiveReviews)")
            print("📊 好评率: \(game.reviewRate)")
            print("🔗 iconUrl字段: \(game.iconUrl ?? "无")")
            print("🎯 gameIconUrl计算值: \(game.gameIconUrl)")
            print("🌐 Steam ID: \(game.steamId)")
            viewModel.game = game
            print("✅ viewModel.game 已设置")
            viewModel.loadUserData()
            print("🔄 已调用 viewModel.loadUserData() 刷新资产和持仓")
            print("=========================")
        }
        .alert("交易结果", isPresented: $viewModel.showAlert) {
            Button("确定") {
                if viewModel.isTransactionSuccessful {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
    // MARK: - 游戏信息卡片
    private var gameInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                // 游戏图标 - 智能加载
                VStack {
//                    Text("图标调试 - \(game.name)")
//                        .font(.caption2)
//                        .foregroundColor(.red)
//                        .onAppear {
//                            print("🔥🔥🔥 红色调试文字出现！游戏：\(game.name)")
//                        }
                    
                    // 强制测试组件创建
                    let iconView = TradingGameIconView.medium(game: game)
                    iconView
                        .onAppear {
                            print("🔥🔥🔥 TradingGameIconView.medium 被调用: \(game.name)")
                        }
                        .background(Color.yellow.opacity(0.3))
                        .border(Color.red, width: 2)
                }
                .onAppear {
                    print("🔥🔥🔥 图标容器出现: \(game.name)")
                    print("🔥🔥🔥 游戏数据检查：")
                    print("   - name: \(game.name)")
                    print("   - iconUrl: \(game.iconUrl ?? "nil")")
                    print("   - gameIconUrl: \(game.gameIconUrl)")
                }
                .background(Color.green.opacity(0.2))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(game.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text("Steam ID: \(game.steamId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("当前股价")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(game.formattedPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
            
            // 游戏统计信息
            HStack(spacing: 20) {
                StatItem(title: "好评数", value: "\(game.positiveReviews.formatted())")
                StatItem(title: "好评率", value: game.reviewRatePercentage)
                StatItem(title: "总评论", value: "\(game.calculatedTotalReviews.formatted())")
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - 用户资产信息卡片
    private var userAssetCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("资产概览")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "wallet.pass.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            HStack(spacing: 20) {
                // 可用现金
                VStack(alignment: .leading, spacing: 4) {
                    Text("可用现金")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(viewModel.availableCash, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // 当前持仓
                VStack(alignment: .trailing, spacing: 4) {
                    Text("当前持仓")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.currentHolding) 股")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // 持仓价值
                VStack(alignment: .trailing, spacing: 4) {
                    Text("持仓价值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(Double(viewModel.currentHolding) * game.currentPrice, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            // 风险提示
            if viewModel.tradingType == .buy && viewModel.totalAmount > viewModel.availableCash * 0.8 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("提醒：此次交易将使用您80%以上的可用现金")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 交易类型选择器
    private var tradingTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("交易类型")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(TradingType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.tradingType = type
                    }) {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.tradingType == type ? .white : type.color)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.tradingType == type ? type.color : Color.gray.opacity(0.1)
                        )
                        .cornerRadius(25)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - 数量选择器
    private var quantitySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("交易数量")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // 减少按钮
                Button(action: {
                    viewModel.decreaseQuantity()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.quantity > 1 ? .blue : .gray)
                }
                .disabled(viewModel.quantity <= 1)
                
                // 数量显示
                Text("\(viewModel.quantity)")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(minWidth: 60)
                
                // 增加按钮
                Button(action: {
                    viewModel.increaseQuantity()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // 快速选择按钮
                HStack(spacing: 8) {
                    ForEach([10, 50, 100], id: \.self) { amount in
                        Button("\(amount)") {
                            viewModel.quantity = amount
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            
            // 可用余额/持仓信息
            if viewModel.tradingType == .buy {
                Text("可用现金: $\(viewModel.availableCash, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("持有数量: \(viewModel.currentHolding) 股")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - 交易总额卡片
    private var totalAmountCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("交易总额")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("$\(viewModel.totalAmount, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.tradingType.color)
            }
            
            HStack {
                Text("单价: \(game.formattedPrice)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("数量: \(viewModel.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [viewModel.tradingType.color.opacity(0.1), viewModel.tradingType.color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.tradingType.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - 交易按钮
    private var tradingButton: some View {
        Button(action: {
            viewModel.executeTrade()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: viewModel.tradingType.icon)
                }
                
                Text(viewModel.tradingType == .buy ? "买入 \(game.name)" : "卖出 \(game.name)")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: viewModel.canExecuteTrade ? 
                        [viewModel.tradingType.color, viewModel.tradingType.color.opacity(0.8)] :
                        [Color.gray, Color.gray.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(!viewModel.canExecuteTrade || viewModel.isLoading)
    }
}

// MARK: - 统计信息组件
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 交易类型枚举
enum TradingType: CaseIterable {
    case buy, sell
    
    var displayName: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        }
    }
    
    var icon: String {
        switch self {
        case .buy: return "arrow.up.circle.fill"
        case .sell: return "arrow.down.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .buy: return .green
        case .sell: return .red
        }
    }
}

// MARK: - 预览
struct TradingView_Previews: PreviewProvider {
    static var previews: some View {
        TradingView(game: Game.sampleGames[0])
    }
} 
