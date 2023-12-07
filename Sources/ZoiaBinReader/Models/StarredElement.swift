//
//  File.swift
//  
//
//  Created by Seth Howard on 12/6/23.
//

import Foundation


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
