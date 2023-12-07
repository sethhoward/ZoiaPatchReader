//
//  File.swift
//  
//
//  Created by Seth Howard on 12/6/23.
//

import Foundation

/// describes the connections between modules inputs and outputs.
public struct Connection {
    let sourceIndex: UInt32
    let sourceBlock: UInt32
    let destinationIndex: UInt32
    let destinationBlock: UInt32
    let connectionStrength: UInt32
}
