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
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// 加载交易历史
    func loadTransactions() {
        isLoading = true
        errorMessage = nil
        networkManager.autoLoginTestUser()
            .flatMap { [weak self] _ -> AnyPublisher<[Transaction], NetworkError> in
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
                        break
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                        self?.transactions = Transaction.sampleTransactions
                    }
                },
                receiveValue: { [weak self] transactions in
                    self?.transactions = transactions
                }
            )
            .store(in: &cancellables)
    }
}

struct TransactionHistoryView: View {
    @StateObject private var viewModel = TransactionHistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("加载中...")
                        Spacer()
                    }
                } else if viewModel.transactions.isEmpty {
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
                    List(viewModel.transactions.sorted(by: { $0.timestamp > $1.timestamp })) { transaction in
                        TransactionRow(transaction: transaction)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                }
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
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            // 交易类型图标
            Image(systemName: transaction.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title2)
                .foregroundColor(transaction.type == .buy ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.gameName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(formatDate(transaction.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type.displayName) \(transaction.quantity)股")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Ⓖ\(String(format: "%.2f", transaction.price))")
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
            gameName: "Counter-Strike 2",
            type: .buy,
            quantity: 3,
            price: 215.46,
            totalAmount: 646.38,
            timestamp: Date().addingTimeInterval(-3600)
        ),
        Transaction(
            id: 2,
            gameId: 730,
            gameName: "Counter-Strike 2",
            type: .sell,
            quantity: 1,
            price: 220.30,
            totalAmount: 220.30,
            timestamp: Date().addingTimeInterval(-1800)
        )
    ]
} 