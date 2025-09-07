//
//  Color+Extensions.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import SwiftUI

extension Color {
    // MARK: - TaskOrbit Brand Colors
    static let taskOrbitOrange = Color(hex: "#FF3C00")
    static let taskOrbitBackground = Color(UIColor.systemBackground)
    static let taskOrbitSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let taskOrbitTertiary = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Task Priority Colors
    static let priorityLow = Color.blue
    static let priorityMedium = Color.green
    static let priorityHigh = Color.orange
    static let priorityUrgent = Color.red
    
    // MARK: - Project Status Colors
    static let statusPlanning = Color.blue
    static let statusActive = Color.green
    static let statusOnHold = Color.yellow
    static let statusCompleted = Color.purple
    static let statusCancelled = Color.red
    
    // MARK: - Financial Colors
    static let profitGreen = Color(hex: "#34C759")
    static let lossRed = Color(hex: "#FF3B30")
    static let budgetWarning = Color(hex: "#FF9500")
    static let neutralGray = Color(hex: "#8E8E93")
    
    // MARK: - Accent Colors for Dark Mode Support
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let tertiaryText = Color(UIColor.tertiaryLabel)
    
    // MARK: - Chart Colors
    static let chartColors: [Color] = [
        .taskOrbitOrange,
        .blue,
        .green,
        .purple,
        .pink,
        .yellow,
        .cyan,
        .mint
    ]
    
    // MARK: - Custom Initializer for Hex Colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Dynamic Colors for Light/Dark Mode
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // MARK: - Gradient Definitions
    static let taskOrbitGradient = LinearGradient(
        colors: [taskOrbitOrange, Color(hex: "#FF6B35")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [profitGreen, Color(hex: "#30D158")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [budgetWarning, Color(hex: "#FFCC02")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let errorGradient = LinearGradient(
        colors: [lossRed, Color(hex: "#FF6961")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Utility Functions
extension Color {
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return self.adjustBrightness(by: abs(percentage))
    }
    
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjustBrightness(by: -abs(percentage))
    }
    
    func adjustBrightness(by percentage: CGFloat) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return Color(
            red: min(max(red + (percentage / 100.0), 0.0), 1.0),
            green: min(max(green + (percentage / 100.0), 0.0), 1.0),
            blue: min(max(blue + (percentage / 100.0), 0.0), 1.0),
            opacity: alpha
        )
    }
}
