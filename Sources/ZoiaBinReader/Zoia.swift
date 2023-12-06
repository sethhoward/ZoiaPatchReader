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

// MARK: - Zoia


/// The model produced from reading a .bin
public struct Zoia {
    // MARK: - Header
    public struct Header {
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
    
    /// defines the size of the patch definition and the patch name.
    internal let header: Header
    /// contains data for each module used in the patch. Modules consist of blocks and connections.
    internal let modules: [Module]
    /// connections between modules inputs and outputs.
    public let connections: [Connection]
    internal let pageNames: [String]
    /// ZOIA stars can be applied either to individual module's parameters or to connections. Currently unsupported always return nothing.
    internal let starredElements: [StarredElement]?
    
    /// Hashmap of keyvalue page number and the cooresponding modules.
    public let pages: [Page]
    
    // TODO: is not currently set.. a hint might be on page 127 of the module list.
    public let isBuro = false
    
    public var description: String {
        return """
        isBuro: \(isBuro),
        name: \(header.name),
        size: \(header.byteCount),
        pages: \(pages.count),
        page temp: \(pageNames.count),
        modules: \(modules.count),
        connections: \(connections.count)
        """
    }
    
    init(header: Header, modules: [Module], connections: [Connection], pageNames: [String], starredElements: [StarredElement]?) {
        self.header = header
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
extension Zoia {
    public enum Color: Int {
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
    
    /// Client helper method.
    public static func mockModule() -> Module {
        return Module(size: 1, type: 1, unknown: 0, pageNumber: 0, oldColor: 1, gridPosition: 0, userParamCount: 0, version: 1, options: [0,0,0,0,0,0,0,0], additionalOptions: nil, customName: "Mock", additionalInfo: .audio_input, color: .lime)
    }
}

public struct Page {
    /// Custom name if provided by the patch creator.
    public let name: String?
    /// Modules available on this page.
    public let modules: [Module]
    /// The page number. These are generally sequencial but Zoia provides uses page 127 for `Modules` available on the stomp pedal or Euro.
    public let number: Int
    
    /// Returns the modules at a certain index. Modules may overlap each other resulting in more than one module at an index.
    /// - Parameter index: Where to look for the module.
    /// - Returns: Module(s) found at index. Modules can be varying sizes and overlap. Returns modules that overlap with the index.
    public func module(gridPosition position: Int) -> [Module]? {
        return modules.filter {
            $0.range.contains(position)
        }
    }
}

// MARK: - Module
public struct Module: CustomStringConvertible, Identifiable, Hashable {
    internal let version: Int
    internal let options: [Int]
    
    private let size: Int
    private let type: Int
    private let unknown: Int
    private let oldColor: Int
    private let userParamCount: Int
    private let additionalOptions: [Int]?
    private let additionalInfo: ModuleType
    
    public let id = UUID()
    public let pageNumber: Int
    // Position on the grid per page. Starting from zero. There are five rows. First row would be 0 - 7. Second row 8 - 15 and so on.
    public let gridPosition: Int
    /// User provided name of the module. This did not exist in earlier Zoia releases. eg. "MyModule"
    public let customName: String?
    public let color: Zoia.Color
    /// The default name provided by Zoia. eg. "Sequencer"
    public var name: String {
        return additionalInfo.name
    }
    /// Description provided by Zoia that explains what the module is used for and how it's used.
    public var detailDescription: String {
        return additionalInfo.description
    }
    /// Provides a list of active  blocks in the module. Either default or set by the user.
    public lazy var blocks: [BlockInfo] = {
        return additionalInfo.activeBlocks(for: self)
    }()
    
    public var description: String {
        return """
        size = \(size)
        pageNumber = \(pageNumber)
        gridPosition = \(gridPosition)
        color = \(color)
        additionalOption = \(String(describing: additionalOptions))
        modname = \(String(describing: customName))
        additionalInfo = \(additionalInfo)
        options = \(options)
        blocks = \(additionalInfo.blocks)
        name = \(additionalInfo.name)
        """
    }
    
    public var range: Range<Int> {
        let start = gridPosition
        let end = start + additionalInfo.activeBlocks(for: self).count
        return start..<end
    }
    
    internal init(size: Int, type: Int, unknown: Int, pageNumber: Int, oldColor: Int, gridPosition: Int, userParamCount: Int, version: Int, options: [Int], additionalOptions: [Int]?, customName: String?, additionalInfo: ModuleType, color: Zoia.Color) {
        self.size = size
        self.type = type
        self.unknown = unknown
        self.pageNumber = pageNumber
        self.oldColor = oldColor
        self.gridPosition = gridPosition
        self.userParamCount = userParamCount
        self.version = version
        self.options = options
        self.additionalOptions = additionalOptions
        self.customName = customName
        self.additionalInfo = additionalInfo
        self.color = color
    }
}

/// describes the connections between modules inputs and outputs.
public struct Connection {
    let sourceIndex: UInt32
    let sourceBlock: UInt32
    let destinationIndex: UInt32
    let destinationBlock: UInt32
    let connectionStrength: UInt32
}
