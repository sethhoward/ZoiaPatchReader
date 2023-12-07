//
//  ZoiaFile.swift
//  
//
//  Created by Seth Howard on 7/4/23.
//

import Foundation

#if os(iOS)
    import UIKit
    public typealias ZColor = UIColor
#elseif os(OSX)
    import AppKit
    public typealias ZColor = NSColor
#endif

public let IO_PAGE = 127

// MARK: - Zoia
/// The model produced from reading a .bin
public struct ZoiaPatch {
    // TODO: unsure if needed
    private let byteSize: Int
    
    // TODO: consider whether or not this is needed
    /// contains data for each module used in the patch. Modules consist of blocks and connections.
    internal let modules: [Module]
    /// connections between modules inputs and outputs.
    internal let pageNames: [String]
    /// ZOIA stars can be applied either to individual module's parameters or to connections. Currently unsupported always return nothing.
    internal let starredElements: [StarredElement]?
    
    /// Hashmap of keyvalue page number and the cooresponding modules.
    public let pages: [Page]
    public let patchName: String
    public let connections: [Connection]
    
    // TODO: is not currently set.. a hint might be on page 127 of the module list.
    public let isBuro = false
    
    public var description: String {
        return """
        isBuro: \(isBuro),
        name: \(patchName),
        size: \(byteSize),
        pages: \(pages.count),
        page temp: \(pageNames.count),
        modules: \(modules.count),
        connections: \(connections.count)
        """
    }
    
    init(header: Header, modules: [Module], connections: [Connection], pageNames: [String], starredElements: [StarredElement]?) {
        self.patchName = header.name
        self.byteSize = header.byteCount
        self.modules = modules
        self.connections = connections
        self.pageNames = pageNames
        self.starredElements = starredElements
        self.pages = {
            var pages = modules.reduce(into: [Int: [Module]]()) { hashmap, module in
                hashmap[module.pageNumber] = (hashmap[module.pageNumber] ?? []) + [module]
            }
            
            return pages.map { page in
                var name: String? {
                    guard page.key < pageNames.count else { return nil }
                    return pageNames[page.key]
                }
                
                return Page(name: name, modules: page.value, number: page.key)
            }.sorted { $0.number < $1.number }
        }()
    }
}

// Mark: - Zoia Color
extension ZoiaPatch {
    /// Client helper method.
    public static func mockModule() -> Module {
        return Module(size: 1, type: 1, unknown: 0, pageNumber: 0, oldColor: 1, gridPosition: 0, userParamCount: 0, version: 1, options: [0,0,0,0,0,0,0,0], additionalOptions: nil, customName: "Mock", additionalInfo: .audio_input, color: .lime)
    }
}

// MARK: - Header
internal struct Header {
    internal let byteCount: Int
    internal let name: String
    internal let moduleCount: Int
}

// TODO: currently not supported
/// ZOIA stars can be applied either to individual module's parameters or to connections
internal struct StarredElement {
    enum ElementType: Int {
        case parameter = 0
        case connection
    }
    
    let type: ElementType
    let moduleIndex: Int
    let inputBlockIndex: Int?
    let midiCCValue: Int
}

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
