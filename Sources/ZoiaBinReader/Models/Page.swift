//
//  File.swift
//  
//
//  Created by Seth Howard on 12/6/23.
//

import Foundation

public struct Page: Hashable {
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
    
    public init(name: String?, modules: [Module], number: Int) {
        self.name = name
        self.modules = modules
        self.number = number
    }
}
