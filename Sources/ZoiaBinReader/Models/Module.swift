//
//  File.swift
//  
//
//  Created by Seth Howard on 12/6/23.
//

import Foundation

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
