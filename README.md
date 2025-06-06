# GameStock

## 目录结构

```
GameStock/
  Views/
    MarketView.swift           # 市场/游戏列表
    TradingView.swift          # 交易界面
    PortfolioView.swift        # 资产组合/持仓
    TransactionHistoryView.swift # 交易历史
    GameDetailView.swift       # 游戏详情
  ViewModels/
    MarketViewModel.swift
    TradingViewModel.swift
    PortfolioViewModel.swift
    GameDetailViewModel.swift
  Models/
    Game.swift
    User.swift
  Utils/
    GameIconView.swift         # 智能游戏图标加载组件
    ColorExtensions.swift
```

## 主要功能

- 市场界面：展示全部可交易游戏，支持搜索、排序
- 交易界面：买入/卖出游戏股票，自动刷新资产
- 资产组合：显示持仓、总资产、收益趋势，icon自动联动
- 交易历史：查看所有买卖记录
- 智能图标加载：`GameIconView` 支持多重后备URL，自动适配Steam图标
- 全部调试文本、版本号等已隐藏，界面简洁

## 最新进展

- 资产icon与后端联动，调试文本全部隐藏
- 资产、持仓、余额等数据实时刷新
- 代码结构优化，便于维护和扩展

---

如需详细开发说明或接口文档，请见 `api_specification.json` 或后端README。