//
//  FileReader.swift
//  ZoiaTest
//
//  Created by Seth Howard on 6/26/23.
//

import Foundation

class FileReader {
    enum FileReaderError: Error {
        case fileNotFound(message: String)
        case invalidHeader
        case invalidModule(index: Int)
        case invalidConnection(index: Int)
    }
    
    private var fileData: Data
    
    private lazy var moduleCount: Int = {
        return Int(readData(range: HeaderField.numberOfModulesRange, as: UInt32.self) ?? 0)
    }()
    
    private lazy var connectionCount: Int = {
        var readHead = HeaderField.size + moduleListSize
        return Int(readData(range: range(forReadHead: &readHead, to: ConnectionField.count.byteLength), as: UInt32.self) ?? 0)
    }()
    
    private lazy var pageCount: Int = {
        var readHead = HeaderField.size + moduleListSize + connectionFieldSize
        return Int(readData(range: range(forReadHead: &readHead, to: PagesField.count.byteLength), as: UInt32.self) ?? 0)
    }()
    
    private lazy var starCount: Int = {
        var readHead = HeaderField.size + moduleListSize + connectionFieldSize + pageNameListSize
        return Int(readData(range: range(forReadHead: &readHead, to: StarField.count.byteLength), as: UInt32.self) ?? 0)
    }()
    
    private lazy var moduleListSize: Int = {
        var readHead = HeaderField.size
        var totalSize: UInt32 = 0
        
        for i in 0..<moduleCount {
            var size = (readData(range: range(forReadHead: &readHead, to: ModuleField.size.byteLength), as: UInt32.self) ?? 0) * 4
            totalSize += size
            
            readHead += Int(size) - ModuleField.size.byteLength
        }
        
        return Int(totalSize)
    }()
    
    private lazy var connectionFieldSize: Int = {
        return connectionCount * ConnectionField.listSize + ConnectionField.count.byteLength
    }()
    
    private lazy var pageNameListSize: Int = {
        return pageCount * PagesField.listSize + PagesField.count.byteLength
    }()
    
    private lazy var starListSize: Int = {
        return starCount * StarField.count.byteLength
    }()

    init(fileURL: URL?) throws {
        guard let fileURL = fileURL else {
            throw FileReaderError.fileNotFound(message: "Invalid URL")
        }
        
        do {
            self.fileData = try Data(contentsOf: fileURL)
        }
        catch {
            throw FileReaderError.fileNotFound(message: "File not found: \(fileURL)")
        }
    }
    
    /// Begin reading the bin provided to `FileReader`
    /// - Returns:`ZoaiFile` that describe read bin file.
    func read() throws -> ZoiaFile {
        do {
            let header = try header()
            let modules = try modules()
            let connections = try connections()
            let pageNames = pageNames()
            let starredElements = starredElements()
            return ZoiaFile(header: header, modules: modules, connections: connections, pageNames: pageNames, starredElements: starredElements)
        } catch(let error) {
            throw error
        }
    }
}

// MARK: - Private
extension FileReader {
    private enum HeaderField {
        case fileSize
        case name
        case moduleCount
        
        var byteLength: Int {
            switch self {
            case .fileSize, .moduleCount:
                return 4
            case .name:
                return 16
            }
        }
        
        static var size: Int {
            return HeaderField.fileSize.byteLength + HeaderField.name.byteLength + HeaderField.moduleCount.byteLength
        }
        
        static var numberOfModulesRange: Range<Int> {
            let start = HeaderField.fileSize.byteLength + HeaderField.name.byteLength
            let to = HeaderField.moduleCount.byteLength + start
            return start..<to
        }
    }

    private enum ModuleField {
        case size
        case type
        case unknown
        case page
        case oldColor
        case gridPosition
        case userParamCount
        case version
        case options
        case additionsOptions(UInt32)
        case name

        var byteLength: Int {
            switch self {
            case .size, .type, .unknown, .page, .oldColor, .gridPosition, .userParamCount, .version:
                    return 4
                case .options:
                    return 8
                case .additionsOptions(let size):
                    guard Int(size) - 40 > 0 else {
                        return 0
                    }
        
                    return Int(size) - 40
                case .name:
                    return 16
            }
        }
    }
    
    private enum ConnectionField {
        case count
        case sourceModule
        case sourceBlock
        case destinationModule
        case destinationBlock
        case connectionStrength
        
        var byteLength: Int {
            return 4
        }
        
        static var listSize: Int {
            return 20
        }
    }
    
    
    private enum PagesField {
        case count
        case name
        
        var byteLength: Int {
            switch self {
            case .count:
                return 4
            case .name:
                return 16
            }
        }
        
        static var listSize: Int {
            return 16
        }
    }
    
    private enum StarField {
        case count
        
        var byteLength: Int {
            return 4
        }
    }
    
    /// Reads a range from the file opened on instantiation of `FileReader`
    /// - Parameters:
    ///   - range: The range to read data (eg. specific variables or the module list)
    ///   - type: The Zoia bin contains UInt8, UInt32, String. as well as arrays of these prmitives.
    /// - Returns: One possible value of UInt8, UInt32, String. as well as arrays.
    private func readData<T>(range: Range<Int>, as type: T.Type) -> T? {
        let subData = fileData.subdata(in: range)
        
        if T.self is String.Type {
            return String(data: subData, encoding: .utf8) as? T
        } else if T.self is [UInt8].Type {
            return Array(subData) as? T
        } else if T.self is [UInt32].Type {
            let count = subData.count / MemoryLayout<UInt32>.size
            return subData.withUnsafeBytes { rawPointer -> T in
                let pointer = rawPointer.bindMemory(to: UInt32.self)
                let buffer = UnsafeBufferPointer(start: pointer.baseAddress, count: count)
                return Array(buffer) as! T
            }
        }
        
        let value = subData.withUnsafeBytes { $0.load(as: T.self) }
        return value
    }

    /// Creates a new range given the offset and the bytes. The result will also update the `offset` parameter.
    /// - Parameters:
    ///   - offset: The start of the range.
    ///   - amount: How many bytes from the offset to read.
    /// - Returns: A `Range` give the results of the parameters passed in.
    private func range(forReadHead offset: inout Int, to amount: Int) -> Range<Int> {
        defer { offset += amount }
        return offset..<(amount + offset)
    }
    
    /// Reads the Zoia file header found at the beginning of the file the `Patch`.
    /// - Returns: `Header` containing the size, name, and the number of modules.
    private func header() throws -> ZoiaFile.Header {
        // Header begins at offset zero in the Zoia patch file.
        var readHead = 0
        
        guard
            let byteCount = readData(range: range(forReadHead: &readHead, to: HeaderField.fileSize.byteLength), as: UInt32.self),
            let name = readData(range: range(forReadHead: &readHead, to: HeaderField.name.byteLength), as: String.self),
            let moduleCount = readData(range: range(forReadHead: &readHead, to: HeaderField.moduleCount.byteLength), as: UInt32.self)
        else {
            throw FileReaderError.invalidHeader
        }
        
        return ZoiaFile.Header(byteCount: Int(byteCount * 4), name: name, moduleCount: Int(moduleCount))
    }
    
    private func modules() throws -> [ZoiaFile.Module] {
        // Track how many bytes we've read for optional fields such as `Additional Options` and `Mod Name`
        var bytesRead = 0
        // Grab the offset of the header so we can begin reading at the beginning of where the module list starts.
        var readHead: Int = HeaderField.size {
            didSet {
                bytesRead += (readHead - oldValue)
            }
        }
        
        // grab the color list first so we can associate them to the modules.
        let colors = colorList()
        
        // Start reading
        let module: (Int) throws -> ZoiaFile.Module = { [self] index in
            // Each iteration we want to reset the bytes read for the next module
            defer { bytesRead = 0 }
            
            guard
                var size = readData(range: range(forReadHead: &readHead, to: ModuleField.size.byteLength), as: UInt32.self),
                let type = readData(range: range(forReadHead: &readHead, to: ModuleField.type.byteLength), as: UInt32.self),
                let unknown = readData(range: range(forReadHead: &readHead, to: ModuleField.unknown.byteLength), as: UInt32.self),
                let pageNumber = readData(range: range(forReadHead: &readHead, to: ModuleField.page.byteLength), as: UInt32.self),
                let oldColor = readData(range: range(forReadHead: &readHead, to: ModuleField.oldColor.byteLength), as: UInt32.self),
                let gridPosition = readData(range: range(forReadHead: &readHead, to: ModuleField.gridPosition.byteLength), as: UInt32.self),
                let userParamCount = readData(range: range(forReadHead: &readHead, to: ModuleField.userParamCount.byteLength), as: UInt32.self),
                let version = readData(range: range(forReadHead: &readHead, to: ModuleField.version.byteLength), as: UInt32.self),
                let options: [UInt8] = readData(range: range(forReadHead: &readHead, to: ModuleField.options.byteLength), as: [UInt8].self)
            else {
                throw FileReaderError.invalidModule(index: index)
            }

            // Broken up here to keep moving the read head forwad corrctly.
            // Size is multiplied by four to get the number of bytes.
            size *= 4
           
            // are there any more bytes to read? If so there are additional options.. maybe even a modname.
            var hasRemainingData: Bool {
                return bytesRead < size
            }
            
            var additionalOptions: [UInt32] {
                guard hasRemainingData else { return [] }

                return readData(range: range(forReadHead: &readHead, to: ModuleField.additionsOptions(size).byteLength), as: [UInt32].self) ?? []
            }
            
            var modname: String {
                guard hasRemainingData else { return "" }
                
                return readData(range: range(forReadHead: &readHead, to: ModuleField.name.byteLength), as: String.self) ?? ""
            }
            
            var color: ZoiaFile.Color {
                return (colors?[index] ?? ZoiaFile.Color(rawValue: Int(oldColor))) ?? .unknown
            }
            
            do {
                return ZoiaFile.Module(index: index, size: Int(size), type: Int(type), unknown: Int(unknown), pageNumber: Int(pageNumber), oldColor: Int(oldColor), gridPosition: Int(gridPosition), userParamCount: Int(userParamCount), version: Int(version), options: options.map{ Int($0) }, additionalOptions: additionalOptions.map{ Int($0) }, modname: modname, additionalInfo: try ZoiaModuleInfoList.module(key: Int(type)), color:color )
            }
            catch let error {
                throw error
            }
        }
        
        var modules: [ZoiaFile.Module] = []
        
        do {
            for i in 0..<moduleCount {
                let module = try module(Int(i))
                print(module)
                modules.append(module)
            }
        } catch let error {
            throw error
        }
        
        print(readHead)
        
        return modules
    }
    
    private func connections() throws -> [ZoiaFile.Connection] {
        var readHead = moduleListSize + HeaderField.size + ConnectionField.count.byteLength
        
        // Start reading
        let connection: (Int) throws -> ZoiaFile.Connection = { [self] index in
            // Each iteration we want to reset the bytes read for the next module
            guard
                let sourceModuleIndex = readData(range: range(forReadHead: &readHead, to: ConnectionField.sourceModule.byteLength), as: UInt32.self),
                let sourceBlockIndex = readData(range: range(forReadHead: &readHead, to: ConnectionField.sourceBlock.byteLength), as: UInt32.self),
                let destinationModuleIndex = readData(range: range(forReadHead: &readHead, to: ConnectionField.destinationModule.byteLength), as: UInt32.self),
                let destinationBlockIndex = readData(range: range(forReadHead: &readHead, to: ConnectionField.destinationBlock.byteLength), as: UInt32.self),
                let connectionStrength = readData(range: range(forReadHead: &readHead, to: ConnectionField.connectionStrength.byteLength), as: UInt32.self)
            else {
                throw FileReaderError.invalidConnection(index: index)
            }
            
            return ZoiaFile.Connection(sourceIndex: sourceModuleIndex, sourceBlock: sourceBlockIndex, destinationIndex: destinationModuleIndex, destinationBlock: destinationBlockIndex, connectionStrength: connectionStrength)
        }
        
        var connections: [ZoiaFile.Connection] = []
        
        do {
            for i in 0..<connectionCount {
                let connection = try connection(Int(i))
                print(connection)
                connections.append(connection)
            }
        } catch let error {
            throw error
        }

        return connections
    }
    
    private func pageNames() -> [String] {
        var readHead = HeaderField.size + moduleListSize + connectionFieldSize + PagesField.count.byteLength
        
        return {
            var names: [String] = []
            
            for _ in 0..<pageCount {
                let name = readData(range: range(forReadHead: &readHead, to: PagesField.name.byteLength), as: String.self) ?? ""
                print(name)
                names.append(name)
            }
            
            return names
        }()
    }
    
    private func starredElements() -> [ZoiaFile.StarredElement]? {
        let readHead = HeaderField.size + moduleListSize + connectionFieldSize + pageNameListSize + StarField.count.byteLength
        
        if starCount > 0 {
            fatalError("Found a star")
        }
        
      //  print(readHead)
        
        return nil
    }
    
    private func colorList() -> [ZoiaFile.Color]? {
        var readHead = 0
        let fileSize = Int(readData(range: range(forReadHead: &readHead, to: HeaderField.fileSize.byteLength), as: UInt32.self) ?? 0) * 4
        readHead = HeaderField.size + moduleListSize + connectionFieldSize + pageNameListSize + starListSize + StarField.count.byteLength
        // there is no count.. we just read until we hit the end of the file.
        var colors: [ZoiaFile.Color]?
        while readHead < fileSize {
            let colorValue = Int(readData(range: range(forReadHead: &readHead, to: 4), as: UInt32.self) ?? 0)
            let color = ZoiaFile.Color(rawValue: colorValue) ?? .unknown
            colors?.append(color)
        }
        
        return colors
    }
}

// MARK: -
struct ZoiaFile {
    struct Header {
        let byteCount: Int
        let name: String
        let moduleCount: Int
    }
    
    struct Module: CustomStringConvertible {
        let index: Int
        let size: Int
        let type: Int
        let unknown: Int
        let pageNumber: Int
        let oldColor: Int
        let gridPosition: Int
        let userParamCount: Int
        let version: Int
        let options: [Int]
        let additionalOptions: [Int]?
        let modname: String
        let additionalInfo: ZoiaModuleInfoList.Module
        let color: Color
        
        var description: String {
            return """
            \nsize = \(size)
            pageNumber = \(pageNumber)
            gridPosition = \(gridPosition)
            color = \(color)
            options = \(options)
            additionalOption = \(String(describing: additionalOptions))
            modname = \(modname)
            additionalInfo = \(additionalInfo)
            name = \(additionalInfo.name)
            """
        }
    }
    
    struct Connection {
        let sourceIndex: UInt32
        let sourceBlock: UInt32
        let destinationIndex: UInt32
        let destinationBlock: UInt32
        let connectionStrength: UInt32
    }
    
    struct StarredElement {
        enum ElementType: Int {
            case parameter = 0
            case connection
        }
        
        let type: ElementType
        let moduleIndex: Int
        let inputBlockIndex: Int?
        let midiCCValue: Int
    }
    
    let header: Header
    let modules: [Module]
    let connections: [Connection]
    let pageNames: [String]
    let starredElements: [StarredElement]?
    
    var pages: [Module] {
        return modules.sorted {
            if $0.pageNumber == $1.pageNumber {
                return $0.gridPosition < $1.gridPosition
            } else {
                return $0.pageNumber < $1.pageNumber
            }
        }
    }
}

extension ZoiaFile {
    enum Color: Int {
        case unknown = 0
        case blue
        case green
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
    }
}
