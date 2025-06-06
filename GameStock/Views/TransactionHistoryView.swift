//
//  TransactionHistoryView.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/5.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TransactionHistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filteredTransactions: [Transaction] = []
    @Published var selectedFilter: TransactionFilter = .all
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var totalProfit: Double {
        transactions.filter { $0.type == "sell" }.reduce(0) { total, transaction in
            // 这里需要计算实际盈亏，简化处理
            return total + (transaction.price * Double(transaction.shares))
        }
    }
    
    var totalInvestment: Double {
        transactions.filter { $0.type == "buy" }.reduce(0) { total, transaction in
            return total + (transaction.price * Double(transaction.shares))
        }
    }
    
    // MARK: - Public Methods
    
    /// 加载交易历史
    func loadTransactions() {
        print("📜 开始加载交易历史...")
        isLoading = true
        errorMessage = nil
        
        // 先确保用户已登录，然后获取交易历史
        networkManager.autoLoginTestUser()
            .flatMap { [weak self] _ -> AnyPublisher<[Transaction], NetworkError> in
                print("✅ 登录成功，开始获取交易历史...")
                guard let self = self else {
                    return Fail(error: NetworkError.networkError(NSError(domain: "TransactionHistoryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"])))
                        .eraseToAnyPublisher()
                }
                return self.networkManager.fetchTransactions()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .finished:
                        print("🎉 交易历史加载完成")
                    case .failure(let error):
                        print("❌ 交易历史加载失败: \(error)")
                        self?.errorMessage = error.localizedDescription
                        // 使用示例数据作为后备
                        self?.transactions = Transaction.sampleTransactions
                        self?.applyFilter()
                    }
                },
                receiveValue: { [weak self] transactions in
                    print("📊 收到交易历史数据: \(transactions.count)笔交易")
                    self?.transactions = transactions
                    self?.applyFilter()
                }
            )
            .store(in: &cancellables)
    }
    
    /// 设置过滤器
    func setFilter(_ filter: TransactionFilter) {
        selectedFilter = filter
        applyFilter()
    }
    
    /// 应用过滤器
    private func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredTransactions = transactions
        case .buy:
            filteredTransactions = transactions.filter { $0.type == "buy" }
        case .sell:
            filteredTransactions = transactions.filter { $0.type == "sell" }
        }
    }
}

enum TransactionFilter: String, CaseIterable {
    case all = "全部"
    case buy = "买入"
    case sell = "卖出"
}

struct TransactionHistoryView: View {
    @StateObject private var viewModel = TransactionHistoryViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计卡片
                statsCard
                
                // 过滤器
                filterSegment
                
                // 交易列表
                transactionsList
            }
            .navigationTitle("交易历史")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.loadTransactions()
            }
            .onAppear {
                viewModel.loadTransactions()
            }
        }
    }
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总投资")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.2f", viewModel.totalInvestment))")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("总交易")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.transactions.count)笔")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var filterSegment: some View {
        Picker("交易类型", selection: $viewModel.selectedFilter) {
            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: viewModel.selectedFilter) { newValue in
            viewModel.setFilter(newValue)
        }
    }
    
    private var transactionsList: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("加载中...")
                    Spacer()
                }
            } else if viewModel.filteredTransactions.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("暂无交易记录")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Text("从市场页面开始您的第一笔交易")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Spacer()
                }
            } else {
                List(viewModel.filteredTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            // 交易类型图标
            Image(systemName: transaction.type == "buy" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title2)
                .foregroundColor(transaction.type == "buy" ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Counter-Strike 2") // 这里应该根据gameId获取游戏名称
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(formatDate(transaction.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == "buy" ? "买入" : "卖出") \(transaction.shares)股")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("$\(String(format: "%.2f", transaction.price))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Transaction 模型扩展
extension Transaction {
    static let sampleTransactions: [Transaction] = [
        Transaction(
            id: 1,
            gameId: 730,
            shares: 3,
            price: 215.46,
            type: "buy",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        Transaction(
            id: 2,
            gameId: 730,
            shares: 1,
            price: 220.30,
            type: "sell",
            timestamp: Date().addingTimeInterval(-1800)
        )
    ]
} 