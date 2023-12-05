//
//  FileReader.swift
//
//  Created by Seth Howard on 6/26/23.
//

import Foundation

public final class ZoiaFileReader {
    enum FileReaderError: Error {
        case fileNotFound(message: String)
        case invalidHeader
        case invalidModule(index: Int)
        case invalidConnection(index: Int)
    }
    
    private var fileData: Data
    private var fileURL: URL
    
    private lazy var moduleCount: Int = {
        return Int(readData(range: PatchHeaderField.numberOfModulesRange, as: UInt32.self) ?? 0)
    }()
    
    private lazy var connectionCount: Int = {
        var readHead = PatchHeaderField.size + moduleListSize
        return Int(readData(range: range(from: &readHead, to: ConnectionField.count.byteLength), as: UInt32.self) ?? 0)
    }()
    
    private lazy var pageCount: Int = {
        var readHead = PatchHeaderField.size + moduleListSize + connectionFieldSize
        return Int(readData(range: range(from: &readHead, to: PagesField.count.byteLength), as: UInt32.self) ?? 0)
    }()
    
    private lazy var starCount: Int = {
        var readHead = PatchHeaderField.size + moduleListSize + connectionFieldSize + pageNameListSize
        return Int(readData(range: range(from: &readHead, to: StarField.count.byteLength), as: UInt32.self) ?? 0)
    }()
    
    private lazy var moduleListSize: Int = {
        var readHead = PatchHeaderField.size
        var totalSize: UInt32 = 0
        
        for i in 0..<moduleCount {
            var size = (readData(range: range(from: &readHead, to: ModuleField.size.byteLength), as: UInt32.self) ?? 0) * 4
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

    public init(fileURL: URL) throws {
        do {
            self.fileData = try Data(contentsOf: fileURL)
            self.fileURL = fileURL
        }
        catch let error {
            throw FileReaderError.fileNotFound(message: "File not found: \(error)")
        }
    }
    
    /// Begin reading the bin provided to `FileReader`
    /// - Returns:`ZoaiFile` that describe read bin file.
    public func read() async throws -> Zoia {
        do {
            let timeStart = Date.now.timeIntervalSince1970
            
            async let header = header()
            async let modules = modules()
            async let connections = connections()
            async let pageNames = pageNames()
            async let starredElements = starredElements()
            
            let timeEnd = Date.now.timeIntervalSince1970
            
            print("Time Taken: \(timeEnd - timeStart)")
            
            return await Zoia(header: try header, modules: try modules, connections: try connections, pageNames: pageNames, starredElements: starredElements)
        } catch let error {
            throw error
        }
    }
}

// MARK: - Private

private extension ZoiaFileReader {
    /*
     A Patch consists of:
     * `PatchHeaderField` This section defines the size of the patch definition and the patch name
     * `ModuleField` This section contains data for each module used in the patch.
     * `ConnectionField` This section describes the connections between modules inputs and outputs.
     * `PagesField` Names This section contains the names assigned to page in the patch. This may be empty.
     * `StarField` This section defines information on starred elements inside the patch.
     ZOIA stars can be applied either to individual module's parameters or to
     connections. Currently unsupported in this reader.
     * Since firmware version 1.10 and above, this section defines the (extended) color assigned to each module
     */
    
    private enum PatchHeaderField {
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
            return PatchHeaderField.fileSize.byteLength + PatchHeaderField.name.byteLength + PatchHeaderField.moduleCount.byteLength
        }
        
        static var numberOfModulesRange: Range<Int> {
            let start = PatchHeaderField.fileSize.byteLength + PatchHeaderField.name.byteLength
            let to = PatchHeaderField.moduleCount.byteLength + start
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
}

private extension ZoiaFileReader {
    /// Reads a range from the file opened on instantiation of `FileReader`
    /// - Parameters:
    ///   - range: The range to read data (eg. specific variables or the module list)
    ///   - type: The Zoia bin contains UInt8, UInt32, String. as well as arrays of these prmitives.
    /// - Returns: One possible value of [UInt8], [UInt32], String. .
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
    private func range(from offset: inout Int, to amount: Int) -> Range<Int> {
        defer { offset += amount }
        return offset..<(amount + offset)
    }
    
    /// Reads the Zoia file header found at the beginning of the file the `Patch`.  Defines the size of the patch definition and the patch name.
    /// - Returns: `Header` containing the size, name, and the number of modules.
    private func header() async throws -> Zoia.Header {
        // Header begins at offset zero in the Zoia patch file.
        return try await withCheckedThrowingContinuation { continuation in
            var readHead = 0
            
            guard
                // the size of the patch file as UInt32. Multiply this value by 4 to get the total number of bytes (done on return).
                let byteCount = readData(range: range(from: &readHead, to: PatchHeaderField.fileSize.byteLength), as: UInt32.self),
                // patch name
                let name = readData(range: range(from: &readHead, to: PatchHeaderField.name.byteLength), as: String.self),
                // he number of module definitions in this patch.
                let moduleCount = readData(range: range(from: &readHead, to: PatchHeaderField.moduleCount.byteLength), as: UInt32.self)
            else {
                continuation.resume(throwing: FileReaderError.invalidHeader)
                return
            }
            
            continuation.resume(returning: Zoia.Header(byteCount: Int(byteCount * 4), name: name, moduleCount: Int(moduleCount)))
        }
    }
    
    private func modules() async throws -> [Zoia.Module] {
        return try await withCheckedThrowingContinuation { continuation in
            // Track how many bytes we've read for optional fields such as `Additional Options` and `Mod Name`
            var bytesRead = 0
            // Grab the offset of the header so we can begin reading at the beginning of where the module list starts.
            var readHead: Int = PatchHeaderField.size {
                didSet {
                    bytesRead += (readHead - oldValue)
                }
            }
            
            // grab the color list first so we can associate them to the modules.
            let colors = colorList()
            
            // Start reading
            let module: (Int) throws -> Zoia.Module = { [self] index in
                // Each iteration we want to reset the bytes read for the next module
                defer { bytesRead = 0 }
                
                guard
                    // the size of the module definition. Multiplied by 4 to get actual byte size.
                    var size = readData(range: range(from: &readHead, to: ModuleField.size.byteLength), as: UInt32.self),
                    //  the module type ID see enum `ModuleType`
                    let type = readData(range: range(from: &readHead, to: ModuleField.type.byteLength), as: UInt32.self),
                    // occasionally has a value of 1 usually 0. More testing needed.
                    let unknown = readData(range: range(from: &readHead, to: ModuleField.unknown.byteLength), as: UInt32.self),
                    // the page number where the module is located. Starts at zero for the first page.
                    let pageNumber = readData(range: range(from: &readHead, to: ModuleField.page.byteLength), as: UInt32.self),
                    // Ussed pre 1.10 firmware. In firmware 1.10 and beyond, the color used to display the module is defined in the module. The value in this field is the closest match old color
                    let oldColor = readData(range: range(from: &readHead, to: ModuleField.oldColor.byteLength), as: UInt32.self),
                    // The position of the first (leftmost) module cell on the page. Numbered 0 to 39. From left to right.
                    let gridPosition = readData(range: range(from: &readHead, to: ModuleField.gridPosition.byteLength), as: UInt32.self),
                    // Most of the time this is the number of values in `additionalOptions`.
                    let userParamCount = readData(range: range(from: &readHead, to: ModuleField.userParamCount.byteLength), as: UInt32.self),
                    // specific version of a module type that was current in the ZOIA when the patch was saved.
                    let version = readData(range: range(from: &readHead, to: ModuleField.version.byteLength), as: UInt32.self),
                    // Values for options 0 to 7 as set by the user when creating or editing the module. These are all single-byte values so they can range from 0 to 255. Options always appear in this list in the same order as in the ZOIA option list for the module being added or changed.
                    let options: [UInt8] = readData(range: range(from: &readHead, to: ModuleField.options.byteLength), as: [UInt8].self)
                else {
                    throw FileReaderError.invalidModule(index: index)
                }
                
                // Size is multiplied by four to get the number of bytes.
                size *= 4
                
                // are there any more bytes to read? If so there are additional options.. maybe even a modname.
                var hasRemainingData: Bool {
                    return bytesRead < size
                }
                
                // There may be any number of additional options including none. Unsure how additional options are currently assigned.
                var additionalOptions: [UInt32] {
                    guard hasRemainingData else { return [] }
                    
                    return readData(range: range(from: &readHead, to: ModuleField.additionsOptions(size).byteLength), as: [UInt32].self) ?? []
                }
                
                // This field is optional. On older patches, modules did not have names. This will be zeroes if the field is present and the user did not change the default module name.
                var modname: String {
                    guard hasRemainingData else { return "" }
                    
                    return readData(range: range(from: &readHead, to: ModuleField.name.byteLength), as: String.self) ?? ""
                }
                
                // assuming we do not have a color we match the closest old color to the new.
                var color: Zoia.Color {
                    return (colors?[index] ?? Zoia.Color(rawValue: Int(oldColor))) ?? .unknown
                }
                
                return Zoia.Module(index: index, size: Int(size), type: Int(type), unknown: Int(unknown), pageNumber: Int(pageNumber), oldColor: Int(oldColor), gridPosition: Int(gridPosition), userParamCount: Int(userParamCount), version: Int(version), options: options.map{ Int($0) }, additionalOptions: additionalOptions.map{ Int($0) }, modname: modname, additionalInfo: ModuleType(rawValue: Int(type))!, color:color )
            }
            
            var modules: [Zoia.Module] = []
            
            do {
                for i in 0..<moduleCount {
                    let module = try module(Int(i))
                   // print(module)
                    modules.append(module)
                }
            } catch let error {
                continuation.resume(throwing: error)
            }

            continuation.resume(returning: modules)
        }
    }
    
    private func connections() async throws -> [Zoia.Connection] {
        return try await withCheckedThrowingContinuation { continuation in
            var readHead = moduleListSize + PatchHeaderField.size + ConnectionField.count.byteLength
            
            // Start reading
            let connection: (Int) throws -> Zoia.Connection = { [self] index in
                // Each iteration we want to reset the bytes read for the next module
                guard
                    // the module index at the source of the connection.
                    let sourceModuleIndex = readData(range: range(from: &readHead, to: ConnectionField.sourceModule.byteLength), as: UInt32.self),
                    // the block index the connection starts in the source module. It's an output block. This may include HIDDEN blocks.
                    let sourceBlockIndex = readData(range: range(from: &readHead, to: ConnectionField.sourceBlock.byteLength), as: UInt32.self),
                    // See abo ve but for destination.
                    let destinationModuleIndex = readData(range: range(from: &readHead, to: ConnectionField.destinationModule.byteLength), as: UInt32.self),
                    let destinationBlockIndex = readData(range: range(from: &readHead, to: ConnectionField.destinationBlock.byteLength), as: UInt32.self),
                    /*
                     The values are in the range 0 to 10000 (base 10) or 0x0 to 0x0270.
                     Connection strength can be dB value or a %.
                     
                     In dB, the range is –100dB to +12.00dB.
                     
                     In %, the range is 0.001%to 398.1%.
                     
                     The formula to convert the <connection strength> to a dB is:
                        -((10000 - <connection strength>) / 100).
                     The formula to convert the <dB value> to a % is:
                        100 * (10 ^ (<dB value> / 20)).
                     */
                    let connectionStrength = readData(range: range(from: &readHead, to: ConnectionField.connectionStrength.byteLength), as: UInt32.self)
                else {
                    throw FileReaderError.invalidConnection(index: index)
                }
                
                return Zoia.Connection(sourceIndex: sourceModuleIndex, sourceBlock: sourceBlockIndex, destinationIndex: destinationModuleIndex, destinationBlock: destinationBlockIndex, connectionStrength: connectionStrength)
            }
            
            var connections: [Zoia.Connection] = []
            
            do {
                for i in 0..<connectionCount {
                    let connection = try connection(Int(i))
                    print(connection)
                    connections.append(connection)
                }
            } catch let error {
                continuation.resume(throwing: error)
            }
            
            continuation.resume(returning: connections)
        }
    }
    
    private func pageNames() async -> [String] {
        return await withCheckedContinuation { continuation in
            var readHead = PatchHeaderField.size + moduleListSize + connectionFieldSize + PagesField.count.byteLength
            
            var names: [String] = []
            
            for _ in 0..<pageCount {
                let name = readData(range: range(from: &readHead, to: PagesField.name.byteLength), as: String.self) ?? ""
                print(name)
                names.append(name)
            }
            
            continuation.resume(returning: names)
        }
    }
    
    private func starredElements() async -> [Zoia.StarredElement]? {
        return await withCheckedContinuation { continuation in
            var _ = PatchHeaderField.size + moduleListSize + connectionFieldSize + pageNameListSize + StarField.count.byteLength
            
            if starCount > 0 {
                fatalError("Found a star")
            }
            
            continuation.resume(returning: nil)
        }
    }
    
    private func colorList() -> [Zoia.Color]? {
        var readHead = 0
        let fileSize = Int(readData(range: range(from: &readHead, to: PatchHeaderField.fileSize.byteLength), as: UInt32.self) ?? 0) * 4
        readHead = PatchHeaderField.size + moduleListSize + connectionFieldSize + pageNameListSize + starListSize + StarField.count.byteLength
        // there is no count.. we just read until we hit the end of the file.
        var colors: [Zoia.Color]?
        while readHead < fileSize {
            let colorValue = Int(readData(range: range(from: &readHead, to: 4), as: UInt32.self) ?? 0)
            let color = Zoia.Color(rawValue: colorValue) ?? .unknown
            colors?.append(color)
        }
        
        return colors
    }
}
