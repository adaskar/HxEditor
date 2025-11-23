//
//  ByteColorScheme.swift
//  HexEditor
//
//  Premium color scheme for different byte types
//

import SwiftUI

enum ByteType {
    case null           // 0x00
    case controlChar    // 0x01-0x1F
    case printableASCII // 0x20-0x7E
    case deleteChar     // 0x7F
    case extendedASCII  // 0x80-0xFF
    
    init(byte: UInt8) {
        switch byte {
        case 0x00:
            self = .null
        case 0x01...0x1F:
            self = .controlChar
        case 0x20...0x7E:
            self = .printableASCII
        case 0x7F:
            self = .deleteChar
        default:
            self = .extendedASCII
        }
    }
}

struct ByteColorScheme {
    // Light Mode Colors
    static let lightModeColors: [ByteType: Color] = [
        .null: Color.gray.opacity(0.4),
        .controlChar: Color.orange.opacity(0.7),
        .printableASCII: Color.primary,
        .deleteChar: Color.red.opacity(0.6),
        .extendedASCII: Color.purple.opacity(0.7)
    ]
    
    // Dark Mode Colors
    static let darkModeColors: [ByteType: Color] = [
        .null: Color.gray.opacity(0.5),
        .controlChar: Color.orange.opacity(0.8),
        .printableASCII: Color.primary,
        .deleteChar: Color.red.opacity(0.7),
        .extendedASCII: Color.blue.opacity(0.8)
    ]
    
    static func color(for byte: UInt8, colorScheme: ColorScheme) -> Color {
        let byteType = ByteType(byte: byte)
        let colors = colorScheme == .dark ? darkModeColors : lightModeColors
        return colors[byteType] ?? .primary
    }
    
    // Background colors for selection
    static let selectionColor = Color.accentColor
    static let selectionTextColor = Color.white
    
    // Colors for UI elements
    static let offsetColor = Color.secondary
    static let gridLineColor = Color.gray.opacity(0.3)
}
