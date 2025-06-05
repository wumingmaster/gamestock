# GameStock iOS 项目设置指南

## 📱 项目基本信息

### 项目配置
- **项目名称**: GameStock
- **Bundle ID**: com.gamestock.ios
- **最低iOS版本**: iOS 16.0+
- **开发语言**: Swift 5.9+
- **UI框架**: SwiftUI
- **架构模式**: MVVM + Combine

### 开发环境要求
- **macOS**: 13.0+ (Ventura或更高)
- **Xcode**: 15.0+
- **Apple Developer Account**: 需要用于真机测试
- **iOS设备**: iPhone (iOS 16.0+)

---

## 🚀 Xcode项目创建步骤

### 第1步：创建新项目
1. 打开Xcode
2. 选择 "Create a new Xcode project"
3. 选择 "iOS" -> "App"
4. 点击 "Next"

### 第2步：项目配置
```
Product Name: GameStock
Team: [选择你的Apple Developer Account]
Organization Identifier: com.gamestock
Bundle Identifier: com.gamestock.ios
Language: Swift
Interface: SwiftUI
Use Core Data: ✅ (勾选)
Include Tests: ✅ (勾选)
```

### 第3步：保存位置
- 选择当前目录：`/Users/xuexiaoyu/work/project/GameStock/GameStock-iOS/`
- 确保 "Create Git repository" 已勾选

---

## 📦 依赖库配置

### Swift Package Manager 依赖
使用 Xcode -> File -> Add Package Dependencies 添加以下包：

1. **Alamofire** (网络请求)
   ```
   https://github.com/Alamofire/Alamofire.git
   版本: 5.8.0+
   ```

2. **Kingfisher** (图片加载)
   ```
   https://github.com/onevcat/Kingfisher.git
   版本: 7.0.0+
   ```

3. **SwiftUI-Introspect** (UI增强)
   ```
   https://github.com/siteline/SwiftUI-Introspect.git
   版本: 1.0.0+
   ```

### 内置框架
以下框架需要在项目中添加：
- `Charts` (iOS 16+ 内置图表框架)
- `Combine` (响应式编程)
- `Core Data` (本地数据存储)
- `LocalAuthentication` (生物识别)
- `UserNotifications` (推送通知)

---

## 🏗️ 项目结构设计

### 创建目录结构
```
GameStock/
├── App/
│   ├── GameStockApp.swift
│   └── ContentView.swift
├── Models/
│   ├── User.swift
│   ├── Game.swift
│   ├── Portfolio.swift
│   └── Transaction.swift
├── Views/
│   ├── Authentication/
│   ├── Market/
│   ├── Portfolio/
│   ├── Trading/
│   └── Profile/
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── MarketViewModel.swift
│   └── PortfolioViewModel.swift
├── Services/
│   ├── NetworkManager.swift
│   ├── APIService.swift
│   └── CoreDataManager.swift
├── Utilities/
│   ├── Extensions.swift
│   ├── Constants.swift
│   └── Helpers.swift
└── Resources/
    ├── Assets.xcassets
    └── GameStock.xcdatamodeld
```

---

## 🔧 项目设置清单

### 基础配置
- [ ] Xcode项目创建完成
- [ ] Bundle ID设置为 `com.gamestock.ios`
- [ ] 最低部署目标设置为 iOS 16.0
- [ ] Team设置为开发者账户
- [ ] Core Data启用

### 依赖集成
- [ ] Alamofire添加完成
- [ ] Kingfisher添加完成
- [ ] SwiftUI-Introspect添加完成
- [ ] Charts框架导入
- [ ] 其他系统框架导入

### 项目结构
- [ ] 基础目录结构创建
- [ ] 数据模型文件创建
- [ ] 视图文件结构创建
- [ ] 服务层文件创建
- [ ] 工具类文件创建

### API连接
- [ ] 网络服务配置
- [ ] API基础URL设置
- [ ] 请求/响应模型定义
- [ ] 错误处理机制

---

## 🎯 下一步计划

### Phase 2.1 完成目标
1. ✅ Xcode项目初始化
2. ⏳ MVVM架构搭建
3. ⏳ Core Data数据层设计
4. ⏳ 网络服务层实现

### 立即行动
1. **现在就做**: 打开Xcode，按照上述步骤创建项目
2. **今天完成**: 基础项目结构和依赖配置
3. **本周目标**: 完成网络层和数据模型设计

---

## 🔗 相关资源

### 文档链接
- [SwiftUI官方文档](https://developer.apple.com/documentation/swiftui/)
- [Combine框架文档](https://developer.apple.com/documentation/combine)
- [Core Data指南](https://developer.apple.com/documentation/coredata)

### API信息
- **Web API地址**: http://localhost:5001
- **API文档**: 参考Web版本 README.txt
- **Steam API密钥**: F7CA22D08BE8B62D94BA5568702B08B2

让我们开始创建你的第一个iOS应用吧！🚀 