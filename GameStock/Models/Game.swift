//
//  Game.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import Foundation
import SwiftUI

// MARK: - Game Model
struct Game: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let steamId: String
    let currentPrice: Double
    let positiveReviews: Int
    let totalReviews: Int?
    let reviewRate: Double
    let salesCount: Int?
    let lastUpdated: Date?
    let iconUrl: String?
    let headerImage: String?
    let nameZh: String?
    
    // 计算属性
    var formattedPrice: String {
        return String(format: "Ⓖ%.2f", currentPrice)
    }
    
    var reviewRatePercentage: String {
        return String(format: "%.1f%%", reviewRate * 100)
    }
    
    var priceChangeColor: Color {
        // 这里可以添加价格变化逻辑
        return currentPrice > 100 ? .green : .red
    }
    
    /// 总评论数计算（如果API没提供则根据好评数和好评率计算）
    var calculatedTotalReviews: Int {
        if let totalReviews = totalReviews {
            return totalReviews
        }
        guard reviewRate > 0 else { return positiveReviews }
        return Int(Double(positiveReviews) / reviewRate)
    }
    
    /// 获取游戏图标URL（带多重后备策略）
    var gameIconUrl: String {
        // 优先使用API返回的图标URL
        if let iconUrl = iconUrl, !iconUrl.isEmpty {
            return iconUrl
        }
        
        // 后备策略1: 胶囊图 (231x87)
        return "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/\(steamId)/capsule_231x87.jpg"
    }
    
    /// 获取游戏头图URL（用于详情页面）
    var gameHeaderUrl: String {
        // 优先使用API返回的头图URL
        if let headerImage = headerImage, !headerImage.isEmpty {
            return headerImage
        }
        
        // 后备策略: Steam头图
        return "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/\(steamId)/header.jpg"
    }
    
    // CodingKeys for API mapping
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case steamId = "steam_id"
        case currentPrice = "current_price"
        case positiveReviews = "positive_reviews"
        case totalReviews = "total_reviews"
        case reviewRate = "review_rate"
        case salesCount = "sales_count"
        case lastUpdated = "last_updated"
        case iconUrl = "icon_url"
        case headerImage = "header_image"
        case nameZh = "name_zh"
    }
    
    // Hash function for Identifiable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 示例数据
extension Game {
    static let sampleGames: [Game] = [
        Game(
            id: 1,
            name: "Counter-Strike 2",
            steamId: "730",
            currentPrice: 168.05,
            positiveReviews: 400000,
            totalReviews: 50000000,
            reviewRate: 0.8,
            salesCount: 50000000,
            lastUpdated: Date(),
            iconUrl: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/730/capsule_231x87.jpg",
            headerImage: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/730/header.jpg",
            nameZh: "反恐精英 2"
        ),
        Game(
            id: 2,
            name: "Dota 2",
            steamId: "570",
            currentPrice: 196.14,
            positiveReviews: 1800000,
            totalReviews: 2200000,
            reviewRate: 0.8182,
            salesCount: 100000000,
            lastUpdated: Date(),
            iconUrl: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/570/capsule_231x87.jpg",
            headerImage: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/570/header.jpg",
            nameZh: "刀塔 2"
        ),
        Game(
            id: 3,
            name: "黑神话：悟空",
            steamId: "2358720",
            currentPrice: 195.67,
            positiveReviews: 814142,
            totalReviews: 20000000,
            reviewRate: 0.9654,
            salesCount: 20000000,
            lastUpdated: Date(),
            iconUrl: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/2358720/capsule_231x87.jpg",
            headerImage: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/2358720/header.jpg",
            nameZh: "黑神话：悟空"
        ),
        Game(
            id: 4,
            name: "Hearts of Iron IV",
            steamId: "394360",
            currentPrice: 71.50,
            positiveReviews: 180000,
            totalReviews: 250000,
            reviewRate: 0.72,
            salesCount: 3000000,
            lastUpdated: Date(),
            iconUrl: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/394360/capsule_231x87.jpg",
            headerImage: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/394360/header.jpg",
            nameZh: "钢铁雄心 4"
        ),
        Game(
            id: 5,
            name: "PUBG: BATTLEGROUNDS",
            steamId: "578080",
            currentPrice: 71.50,
            positiveReviews: 850000,
            totalReviews: 1500000,
            reviewRate: 0.567,
            salesCount: 75000000,
            lastUpdated: Date(),
            iconUrl: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/578080/capsule_231x87.jpg",
            headerImage: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/578080/header.jpg",
            nameZh: "绝地求生"
        ),
        Game(
            id: 6,
            name: "Terraria",
            steamId: "105600",
            currentPrice: 197.73,
            positiveReviews: 814142,
            totalReviews: 843000,
            reviewRate: 0.9654,
            salesCount: 20000000,
            lastUpdated: Date(),
            iconUrl: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/105600/capsule_231x87.jpg",
            headerImage: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/105600/header.jpg",
            nameZh: "泰拉瑞亚"
        ),
        Game(
            id: 7,
            name: "Cyberpunk 2077",
            steamId: "1091500",
            currentPrice: 171.76,
            positiveReviews: 380000,
            totalReviews: 450000,
            reviewRate: 0.8444,
            salesCount: 13000000,
            lastUpdated: Date(),
            iconUrl: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/1091500/capsule_231x87.jpg",
            headerImage: "https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/1091500/header.jpg",
            nameZh: "赛博朋克 2077"
        )
    ]
} 
