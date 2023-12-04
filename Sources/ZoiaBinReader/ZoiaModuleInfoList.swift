//
//  ZoiaModuleList.swift
//  ZoiaTest
//
//  Created by Seth Howard on 6/24/23.
//

import Foundation

public struct ZoiaModuleInfoList {
    static private var list: [Module] = {
        let list = loadList()
        let sortedKeys = list.keys.sorted { Int($0)! < Int($1)! }
        return sortedKeys.compactMap { list[$0] }
    }()
    
    static internal subscript(index: Int) -> ZoiaModuleInfoList.Module {
        precondition(index < ZoiaModuleInfoList.list.count, "Index out of bounds")
        return ZoiaModuleInfoList.list[index]
    }

    private static func loadList() -> [String: Module] {
        guard let path = Bundle.module.path(forResource: "ModuleIndex", ofType: "json") else {
            fatalError("ModuleIndex.json not found in bundle")
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            let decoder = JSONDecoder()
            return try decoder.decode([String: Module].self, from: data)
        }
        catch let error {
            fatalError(error.localizedDescription)
        }
    }
}

extension ZoiaModuleInfoList {
    struct Module: Codable {
        let category: String
        let cpu: Double
        let defaultBlockCount: Int
        let description: String
        let maxBlocks: Int
        let minBlocks: Int
        let name: String
        var blocks: [Block]
        var options: [[String: [Option]]]
        let params: Int
        
        enum CodingKeys: String, CodingKey {
            case category
            case cpu
            case defaultBlockCount = "default_blocks"
            case description
            case maxBlocks = "max_blocks"
            case minBlocks = "min_blocks"
            case name
            case blocks
            case options
            case params
        }
        
        subscript(name: String) -> Block? {
            return blocks.first(where: {$0.name == name})
        }
        
        init(from decoder: Decoder) throws {
            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                category = try container.decode(String.self, forKey: .category)
                cpu = try container.decode(Double.self, forKey: .cpu)
                defaultBlockCount = try container.decode(Int.self, forKey: .defaultBlockCount)
                description = try container.decode(String.self, forKey: .description)
                maxBlocks = try container.decode(Int.self, forKey: .maxBlocks)
                minBlocks = try container.decode(Int.self, forKey: .minBlocks)
                name = try container.decode(String.self, forKey: .name)
                
                // Convert blocks from a key value pair to a sorted array based off of the block position
                let unsortedBlocks = try container.decode([String: Block].self, forKey: .blocks)
                blocks = unsortedBlocks.sorted { $0.value.position < $1.value.position }.map { $0.value }
                
                options = try container.decode([[String: [Option]]].self, forKey: .options)
                params = try container.decode(Int.self, forKey: .params)
            } catch let error {
                throw error
            }
        }
    }
    
    public struct Block: Codable {
        let isDefault: Bool
        let isParam: Bool
        let position: Int
        let name: String
        
        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<ZoiaModuleInfoList.Block.CodingKeys> = try decoder.container(keyedBy: ZoiaModuleInfoList.Block.CodingKeys.self)
            self.isDefault = try container.decode(Bool.self, forKey: ZoiaModuleInfoList.Block.CodingKeys.isDefault)
            self.isParam = try container.decode(Bool.self, forKey: ZoiaModuleInfoList.Block.CodingKeys.isParam)
            self.position = try container.decode(Int.self, forKey: ZoiaModuleInfoList.Block.CodingKeys.position)
            self.name = container.codingPath.last?.stringValue ?? "ERROR"
        }
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
