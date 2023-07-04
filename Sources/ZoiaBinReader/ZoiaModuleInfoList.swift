//
//  ZoiaModuleList.swift
//  ZoiaTest
//
//  Created by Seth Howard on 6/24/23.
//

import Foundation

struct ZoiaModuleInfoList {
    enum ModuleInfoListError: Error {
        case fileNotFound
        case keyOutOfBound(key: Int)
        case moduleKeyNotFound(key: Int)
    }
    
    static private var list: [String: Module]? = {
        do {
            return try loadList()
        } catch let error {
            print(error)
        }
        
        return nil
    }()
    
    static func module(key: Int) throws -> Module {
        guard let list = list else {
            throw ModuleInfoListError.fileNotFound
        }
        
        guard key < list.count else {
            throw ModuleInfoListError.keyOutOfBound(key: key)
        }
        
        guard let module = list["\(key)"] else {
            throw ModuleInfoListError.moduleKeyNotFound(key: key)
        }
        
        return module
    }
//
//    static func moduleName(key: Int) -> String? {
//        return ZoiaModuleInfoList.module(key: key)?.name
//    }
}

extension ZoiaModuleInfoList {
    struct Module: Codable {
        let category: String
        let cpu: Double
        let default_blocks: Int
        let description: String
        let max_blocks: Int
        let min_blocks: Int
        let name: String
        var blocks: [String: Block]
        var options: [String: [Option]]
        let params: Int
    }
    
    struct Block: Codable {
        let isDefault: Bool
        let isParam: Bool
        let position: Int
    }
    
    struct Option: Codable {
        var value: Codable
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                value = stringValue
            } else if let intValue = try? container.decode(Int.self) {
                value = intValue
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid value type")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch value {
            case let stringValue as String:
                try container.encode(stringValue)
            case let intValue as Int:
                try container.encode(intValue)
            default:
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Invalid value type"))
            }
        }
    }
}

extension ZoiaModuleInfoList {
    private static func loadList() throws -> [String: Module] {
        guard let path = Bundle.main.path(forResource: "ModuleIndex", ofType: "json") else {
            throw ModuleInfoListError.fileNotFound
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            let decoder = JSONDecoder()
            return try decoder.decode([String: Module].self, from: data)
        }
        catch let error {
            throw error
        }
    }
}
