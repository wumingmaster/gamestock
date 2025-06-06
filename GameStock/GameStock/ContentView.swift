//
//  ContentView.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import SwiftUI
// 如果有 GameStock 这个 module，也可以加上
// import GameStock

struct ContentView: View {
    var body: some View {
        TabView {
            MarketView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("市场")
                }
            
            PortfolioView()
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("资产组合")
                }
            
            TransactionHistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("历史")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("个人中心")
                }
        }
        .overlay(
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Text("GameStock v0.0.1")
                        // Text("DEBUG: Tab顺序已更新")
                    }
                    Spacer()
                }
                .padding(.top, 50)
                
                Spacer()
            }
        )
        .onAppear {
            print("🚀 ContentView 已加载 - 新Tab顺序: 市场、资产组合、历史、个人中心")
        }
    }
}

// 简化版的交易历史视图
struct TransactionHistoryViewSimple: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("交易历史")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("记录您的所有交易活动")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    HistoryRow(icon: "arrow.down.circle.fill", title: "买入记录", subtitle: "查看所有买入交易", color: .green)
                    HistoryRow(icon: "arrow.up.circle.fill", title: "卖出记录", subtitle: "查看所有卖出交易", color: .red)
                    HistoryRow(icon: "chart.line.uptrend.xyaxis", title: "盈亏分析", subtitle: "交易收益统计", color: .blue)
                    HistoryRow(icon: "calendar", title: "月度报告", subtitle: "按月查看交易情况", color: .orange)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Text("从市场页面开始您的第一笔交易")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .navigationTitle("历史")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HistoryRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("GameStock")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("v0.0.1 Beta")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    ProfileRow(icon: "person.circle", title: "个人资料", action: {})
                    ProfileRow(icon: "gear", title: "设置", action: {})
                    ProfileRow(icon: "questionmark.circle", title: "帮助与支持", action: {})
                    ProfileRow(icon: "info.circle", title: "关于我们", action: {})
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Text("© 2025 GameStock Team")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .navigationTitle("个人中心")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 