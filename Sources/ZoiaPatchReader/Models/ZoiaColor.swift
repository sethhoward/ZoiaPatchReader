//
//  File.swift
//  
//
//  Created by Seth Howard on 12/6/23.
//

import Foundation

public enum ZoiaColor: Int {
    case unknown = 0
    case blue
    case green
    case red
    case yellow
    case aqua
    case magenta
    case white
    case orange
    case lime
    case surf
    case sky
    case purple
    case pink
    case peach
    case mango

    public var value: ZColor {
        switch self {
        case .blue:
            return .blue
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .aqua:
            return ZColor(red: 0, green: 255/255, blue: 255/255, alpha: 1)
        case .magenta:
            return .magenta
        case .orange:
            return .orange
        case .lime:
            return ZColor(red: 50/255, green: 205/255, blue: 50/255, alpha: 1)
        case .surf:
            return ZColor(red: 10/255, green: 255/255, blue: 100/255, alpha: 1)
        case .sky:
            return ZColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 1)
        case .purple:
            return .purple
        case .pink:
            return .systemPink
        case .peach:
            return ZColor(red: 255/255, green: 218/255, blue: 185/255, alpha: 1)
        case .mango:
            return ZColor(red: 244/255, green: 187/255, blue: 68/255, alpha: 1)
        case .unknown, .white:
            return .white
        case .red:
            return .red
        }
    }
}
