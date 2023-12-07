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
        pages: \(pages.count) \n\(pages),
        connections: \(connections.count)\n\(connections)
        """
    }
    
    init(header: Header, modules: [Module], connections: [Connection], pageNames: [String], starredElements: [StarredElement]?) {
        self.patchName = header.name
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

extension ZoiaPatch {
    /// Client helper method.
    public static func mockModule() -> Module {
        return Module(size: 1, type: 1, unknown: 0, pageNumber: 0, oldColor: 1, gridPosition: 0, userParamCount: 0, version: 1, options: [0,0,0,0,0,0,0,0], additionalOptions: nil, customName: "Mock", additionalInfo: .audio_input, color: .lime)
    }
    
    public static func emptyPatch() -> ZoiaPatch {
        return ZoiaPatch(header: Header(byteCount: 0, name: "", moduleCount: 0), modules: [], connections: [], pageNames: [], starredElements: [])
    }
}

// MARK: - Header
internal struct Header {
    internal let byteCount: Int
    internal let name: String
    internal let moduleCount: Int
}
