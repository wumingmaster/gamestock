import Foundation
import Combine

class NetworkManager {
    /// 用户登录
    func login(username: String, password: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let loginData = [
            "username": username,
            "password": password
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: loginData) else {
            return Fail(error: NetworkError.invalidData)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/api/auth/login",
            method: .POST,
            body: jsonData,
            responseType: LoginResponse.self
        )
    }
    
    /// 用户注册
    func register(username: String, email: String, password: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let registerData = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: registerData) else {
            return Fail(error: NetworkError.invalidData)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/api/auth/register",
            method: .POST,
            body: jsonData,
            responseType: LoginResponse.self
        )
    }
    
    /// 获取用户投资组合
    func fetchPortfolio() -> AnyPublisher<Portfolio, NetworkError> {
        return request(
            endpoint: "/api/trading/portfolio",
            method: .GET,
            responseType: Portfolio.self
        )
    }
    
    /// 获取交易历史
    func fetchTransactions() -> AnyPublisher<[Transaction], NetworkError> {
        return request(
            endpoint: "/api/trading/transactions",
            method: .GET,
            responseType: [Transaction].self
        )
    }
    
    /// 买入股票
    func buyStock(gameId: Int, quantity: Int) -> AnyPublisher<TransactionResponse, NetworkError> {
        let tradeData = [
            "game_id": gameId,
            "quantity": quantity
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: tradeData) else {
            return Fail(error: NetworkError.invalidData)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/api/trading/buy",
            method: .POST,
            body: jsonData,
            responseType: TransactionResponse.self
        )
    }
    
    /// 卖出股票
    func sellStock(gameId: Int, quantity: Int) -> AnyPublisher<TransactionResponse, NetworkError> {
        let tradeData = [
            "game_id": gameId,
            "quantity": quantity
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: tradeData) else {
            return Fail(error: NetworkError.invalidData)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/api/trading/sell",
            method: .POST,
            body: jsonData,
            responseType: TransactionResponse.self
        )
    }
}

// MARK: - 网络错误
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidData
    case noData
    case decodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidData:
            return "无效的数据"
        case .noData:
            return "没有数据"
        case .decodingError:
            return "数据解析错误"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
} 