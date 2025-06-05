//
//  NetworkManager.swift
//  GameStock iOS
//
//  网络管理器 - 处理所有API请求
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // MARK: - 配置
    private let baseURL = "http://localhost:5001"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    private init() {
        // 配置URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
    }
    
    // MARK: - 通用请求方法
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: responseType, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError
                } else {
                    return NetworkError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - API方法
    
    /// 获取所有游戏列表
    func fetchGames() -> AnyPublisher<[Game], NetworkError> {
        return request(
            endpoint: "/api/games",
            method: .GET,
            responseType: [Game].self
        )
    }
    
    /// 用户注册
    func register(username: String, email: String, password: String) -> AnyPublisher<User, NetworkError> {
        let registerData = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: registerData) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/api/auth/register",
            method: .POST,
            body: body,
            responseType: User.self
        )
    }
    
    /// 用户登录
    func login(username: String, password: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let loginData = [
            "username": username,
            "password": password
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: loginData) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/api/auth/login",
            method: .POST,
            body: body,
            responseType: LoginResponse.self
        )
    }
    
    /// 获取投资组合
    func fetchPortfolio() -> AnyPublisher<Portfolio, NetworkError> {
        return request(
            endpoint: "/api/trading/portfolio",
            method: .GET,
            responseType: Portfolio.self
        )
    }
    
    /// 买入股票
    func buyStock(gameId: Int, quantity: Int) -> AnyPublisher<TransactionResponse, NetworkError> {
        let buyData = [
            "game_id": gameId,
            "quantity": quantity
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: buyData) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/api/trading/buy",
            method: .POST,
            body: body,
            responseType: TransactionResponse.self
        )
    }
    
    /// 卖出股票
    func sellStock(gameId: Int, quantity: Int) -> AnyPublisher<TransactionResponse, NetworkError> {
        let sellData = [
            "game_id": gameId,
            "quantity": quantity
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: sellData) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/api/trading/sell",
            method: .POST,
            body: body,
            responseType: TransactionResponse.self
        )
    }
}

// MARK: - 辅助类型

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case decodingError
    case networkError(Error)
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

// MARK: - 响应模型

struct LoginResponse: Codable {
    let id: Int
    let username: String
    let email: String
    let balance: Double
    let message: String?
}

struct TransactionResponse: Codable {
    let success: Bool
    let message: String
    let newBalance: Double?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case newBalance = "new_balance"
    }
} 