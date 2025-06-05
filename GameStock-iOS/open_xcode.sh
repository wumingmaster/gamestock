#!/bin/bash

# GameStock iOS - Xcode 快速启动脚本

echo "🍎 GameStock iOS 开发环境启动"
echo "================================"

# 检查Xcode是否安装
if ! command -v xcode-select &> /dev/null; then
    echo "❌ 未检测到Xcode，请先安装Xcode"
    echo "从App Store下载: https://apps.apple.com/us/app/xcode/id497799835"
    exit 1
fi

echo "✅ Xcode已安装"

# 检查Xcode版本
XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo "📱 $XCODE_VERSION"

# 获取当前目录
CURRENT_DIR=$(pwd)
echo "📂 当前目录: $CURRENT_DIR"

echo ""
echo "🚀 准备创建GameStock iOS项目..."
echo ""
echo "⚠️  请按照以下步骤在Xcode中创建项目："
echo ""
echo "1️⃣  打开Xcode后选择: 'Create a new Xcode project'"
echo "2️⃣  选择: iOS > App"
echo "3️⃣  项目配置："
echo "     Product Name: GameStock"
echo "     Team: [选择你的Apple Developer Account]"
echo "     Organization Identifier: com.gamestock"
echo "     Bundle Identifier: com.gamestock.ios"
echo "     Language: Swift"
echo "     Interface: SwiftUI"
echo "     Use Core Data: ✅"
echo "     Include Tests: ✅"
echo ""
echo "4️⃣  保存位置: $CURRENT_DIR"
echo "5️⃣  确保勾选 'Create Git repository'"
echo ""

# 询问是否现在打开Xcode
read -p "🤔 是否现在打开Xcode? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 正在启动Xcode..."
    open -a Xcode
    
    echo ""
    echo "💡 提示："
    echo "  - 创建项目后，参考 PROJECT_SETUP.md 进行配置"
    echo "  - 使用 api_specification.json 作为API开发参考"
    echo "  - Web API运行在: http://localhost:5001"
    echo ""
    echo "📚 有用的资源："
    echo "  - SwiftUI教程: https://developer.apple.com/tutorials/swiftui"
    echo "  - iOS设计指南: https://developer.apple.com/design/human-interface-guidelines/ios"
    echo ""
    echo "🎯 下一步: 完成Xcode项目创建后，开始Phase 2.1的MVVM架构搭建"
else
    echo "👌 好的，你可以稍后手动打开Xcode"
    echo "💻 命令: open -a Xcode"
fi

echo ""
echo "✨ GameStock iOS开发即将开始！" 