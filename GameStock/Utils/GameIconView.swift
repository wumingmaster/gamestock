//
//  GameIconView.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/4.
//

import SwiftUI

/// 智能游戏图标加载组件 - 基于多重后备策略
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
    
    /// 多重后备URL策略（类似Web端实现）
    private var fallbackUrls: [String] {
        var urls: [String] = []
        
        // 主要图标URL（来自API）
        if let iconUrl = game.iconUrl, !iconUrl.isEmpty {
            urls.append(iconUrl)
        }
        
        // 后备策略1: 胶囊图 (231x87)
        urls.append("https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/\(game.steamId)/capsule_231x87.jpg")
        
        // 后备策略2: 小胶囊图 (184x69)
        urls.append("https://steamcdn-a.akamaihd.net/steam/apps/\(game.steamId)/capsule_184x69.jpg")
        
        // 后备策略3: 头图
        urls.append("https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/\(game.steamId)/header.jpg")
        
        // 后备策略4: 库存图
        urls.append("https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/\(game.steamId)/library_600x900.jpg")
        
        return urls
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
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                    case .failure(_):
                        Color.clear
                            .onAppear {
                                tryNextUrl()
                            }
                    @unknown default:
                        loadingPlaceholder
                    }
                }
            } else {
                // 最终占位符（所有URL都失败时）
                finalPlaceholder
            }
        }
        .frame(width: size.width, height: size.height)
        .cornerRadius(cornerRadius)
    }
    
    // MARK: - 占位符组件
    
    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            )
    }
    
    private var finalPlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: min(size.width, size.height) * 0.4))
                        .foregroundColor(.white)
                    
                    if size.width > 60 {  // 只在大图标时显示文字
                        Text("Steam")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            )
    }
    
    // MARK: - 私有方法
    
    private func tryNextUrl() {
        if currentUrlIndex < fallbackUrls.count - 1 {
            currentUrlIndex += 1
            print("🔄 图标加载失败，尝试下一个URL: \(fallbackUrls[currentUrlIndex])")
        } else {
            hasError = true
            print("❌ 所有图标URL都失败，显示占位符 - 游戏: \(game.name)")
        }
    }
}

// MARK: - 便捷初始化方法

extension GameIconView {
    /// 列表行小图标 (50x50)
    static func small(game: Game) -> GameIconView {
        GameIconView(game: game, width: 50, height: 50, cornerRadius: 8)
    }
    
    /// 卡片中等图标 (80x80)
    static func medium(game: Game) -> GameIconView {
        GameIconView(game: game, width: 80, height: 80, cornerRadius: 12)
    }
    
    /// 详情页大图标 (100x100)
    static func large(game: Game) -> GameIconView {
        GameIconView(game: game, width: 100, height: 100, cornerRadius: 16)
    }
    
    /// 自定义尺寸
    static func custom(game: Game, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 8) -> GameIconView {
        GameIconView(game: game, width: width, height: height, cornerRadius: cornerRadius)
    }
}

// MARK: - 预览

struct GameIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                GameIconView.small(game: Game.sampleGames[0])
                GameIconView.medium(game: Game.sampleGames[1])
                GameIconView.large(game: Game.sampleGames[2])
            }
            
            Text("不同尺寸的游戏图标")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 