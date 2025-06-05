//
//  NetworkManager.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // MARK: - 配置
    private let baseURL = "http://10.0.0.31:5001"
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init() {
        // 配置URLSession以支持Cookie
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        
        self.session = URLSession(configuration: config)
        
        print("🍪 NetworkManager初始化完成，Cookie支持已启用")
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
        
        // 打印调试信息
        print("🌐 发送请求到: \(url)")
        print("🔑 HTTP方法: \(method.rawValue)")
        
        // 检查和打印当前的Cookie
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            print("🍪 当前Cookie数量: \(cookies.count)")
            for cookie in cookies {
                print("🍪 Cookie: \(cookie.name)=\(cookie.value)")
            }
        } else {
            print("🍪 无Cookie")
        }
        
        return session.dataTaskPublisher(for: request)
            .map { output in
                print("📡 收到响应数据长度: \(output.data.count) bytes")
                
                // 检查HTTP状态码
                if let httpResponse = output.response as? HTTPURLResponse {
                    print("📡 HTTP状态码: \(httpResponse.statusCode)")
                    
                    // 打印响应头中的Cookie信息
                    if let setCookieHeader = httpResponse.allHeaderFields["Set-Cookie"] as? String {
                        print("🍪 服务器设置Cookie: \(setCookieHeader)")
                        
                        // 手动处理Cookie存储
                        if let url = httpResponse.url {
                            let cookies = HTTPCookie.cookies(withResponseHeaderFields: httpResponse.allHeaderFields as! [String: String], for: url)
                            for cookie in cookies {
                                HTTPCookieStorage.shared.setCookie(cookie)
                                print("🍪 手动存储Cookie: \(cookie.name)=\(cookie.value)")
                            }
                        }
                    }
                    
                    // 如果是401未授权，提前处理
                    if httpResponse.statusCode == 401 {
                        print("❌ 401 未授权错误")
                    }
                }
                
                if let responseString = String(data: output.data, encoding: .utf8) {
                    print("📡 原始响应: \(responseString.prefix(500))")
                }
                return output.data
            }
            .tryMap { data in
                // 检查是否有HTTP错误状态码
                return data
            }
            .decode(type: responseType, decoder: self.jsonDecoder)
            .mapError { error in
                print("❌ 解码错误: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ 缺少字段: \(key), 路径: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("❌ 类型不匹配: 期望 \(type), 路径: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❌ 值不存在: \(type), 路径: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("❌ 数据损坏: \(context)")
                    @unknown default:
                        print("❌ 未知解码错误")
                    }
                    return NetworkError.decodingError
                } else {
                    return NetworkError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - JSON解码器配置
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            print("🗓️ 尝试解析日期: \(dateStr)")
            
            // 尝试不同的日期格式
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss"
            ]
            
            for formatString in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone.current
                
                if let date = formatter.date(from: dateStr) {
                    print("✅ 成功解析日期: \(dateStr) -> \(date)")
                    return date
                }
            }
            
            print("⚠️ 日期解析失败，使用当前时间: \(dateStr)")
            // 如果解析失败，返回当前时间而不是抛出错误
            return Date()
        }
        return decoder
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
    
    /// 自动登录测试用户
    func autoLoginTestUser() -> AnyPublisher<LoginResponse, NetworkError> {
        print("🔐 开始自动登录测试用户...")
        return login(username: "test_trader", password: "password123")
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
            "shares": quantity
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
            "shares": quantity
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