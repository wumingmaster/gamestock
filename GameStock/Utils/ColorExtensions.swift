//
//  ColorExtensions.swift
//  GameStock
//
//  Created by GameStock Team on 2025/6/2.
//

import SwiftUI

extension Color {
    // 跨平台兼容的系统颜色
    static var systemBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(.windowBackground)
        #endif
    }
    
    static var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color.gray.opacity(0.05)
        #endif
    }
    
    static var systemGray6: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    static var label: Color {
        #if os(iOS)
        return Color(UIColor.label)
        #else
        return Color.primary
        #endif
    }
    
    static var secondaryLabel: Color {
        #if os(iOS)
        return Color(UIColor.secondaryLabel)
        #else
        return Color.secondary
        #endif
    }
} 