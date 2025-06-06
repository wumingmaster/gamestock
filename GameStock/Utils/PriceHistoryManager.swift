import Foundation

/// 单条价格历史点
struct LocalPricePoint: Codable {
    let price: Double
    let timestamp: Date
}

/// 本地股价历史管理器（UserDefaults实现）
class PriceHistoryManager {
    static let shared = PriceHistoryManager()
    private let userDefaultsKey = "GameStock_PriceHistory"
    private let queue = DispatchQueue(label: "PriceHistoryManagerQueue")
    
    // [gameId: [LocalPricePoint]]
    private var cache: [Int: [LocalPricePoint]] = [:]
    
    private init() {
        loadAll()
    }
    
    /// 保存一条价格历史
    func savePrice(gameId: Int, price: Double, time: Date = Date()) {
        queue.sync {
            var history = cache[gameId] ?? []
            // 避免同一时刻重复
            if history.last?.timestamp.timeIntervalSince1970 != time.timeIntervalSince1970 {
                history.append(LocalPricePoint(price: price, timestamp: time))
                cache[gameId] = history
                persist()
            }
        }
    }
    
    /// 读取某只股票的历史
    func loadHistory(gameId: Int) -> [LocalPricePoint] {
        queue.sync {
            return cache[gameId] ?? []
        }
    }
    
    /// 读取所有历史
    func loadAll() {
        queue.sync {
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
            if let decoded = try? JSONDecoder().decode([Int: [LocalPricePoint]].self, from: data) {
                cache = decoded
            }
        }
    }
    
    /// 持久化到UserDefaults
    private func persist() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    /// 清空所有历史（调试用）
    func clearAll() {
        queue.sync {
            cache = [:]
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
    
    /// 获取昨日0点或24小时前最近的价格
    func yesterdayPrice(gameId: Int) -> Double? {
        let history = loadHistory(gameId: gameId)
        guard !history.isEmpty else { return nil }
        // 计算昨日0点
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else { return nil }
        // 找到昨日0点之后、今天0点之前的最后一条
        let yesterdayPoints = history.filter { $0.timestamp >= yesterdayStart && $0.timestamp < todayStart }
        if let last = yesterdayPoints.last {
            return last.price
        }
        // 如果没有，找24小时前最近的
        let target = now.addingTimeInterval(-24*60*60)
        let closest = history.min(by: { abs($0.timestamp.timeIntervalSince(target)) < abs($1.timestamp.timeIntervalSince(target)) })
        return closest?.price
    }
} 
