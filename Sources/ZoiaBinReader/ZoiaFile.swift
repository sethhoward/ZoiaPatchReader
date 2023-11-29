//
//  ZoiaFile.swift
//  
//
//  Created by Seth Howard on 7/4/23.
//

import Foundation
import UIKit

// MARK: -
public struct ZoiaFile {
    public struct Header {
        let byteCount: Int
        let name: String
        let moduleCount: Int
    }

    // TODO: I think we want to set what blocks are active on creation
    public struct Module: CustomStringConvertible, Identifiable, Hashable {
        public let id = UUID()
        let index: Int
        let size: Int
        let type: Int
        let unknown: Int
        let pageNumber: Int
        let oldColor: Int
        public let gridPosition: Int
        let userParamCount: Int
        let version: Int
        let options: [Int]
        let additionalOptions: [Int]?
        let modname: String
        // TODO: Let's get rid of this.
        let additionalInfo: ModuleType
        public let color: Color
        public var name: String {
            return additionalInfo.name
        }
        public var info: String {
            return additionalInfo.description
        }
        
        var range: Range<Int>!
        
        public init(index: Int, size: Int, type: Int, unknown: Int, pageNumber: Int, oldColor: Int, gridPosition: Int, userParamCount: Int, version: Int, options: [Int], additionalOptions: [Int]?, modname: String, additionalInfo: ModuleType, color: Color) {
            self.index = index
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
            self.modname = modname
            self.additionalInfo = additionalInfo
            self.color = color
            self.range = {
                let start = gridPosition
                let end = gridPosition + additionalInfo.activeBlocks(for: self).count
                return start..<end
            }()
        }
    
        
        public var description: String {
            return """
            \nsize = \(size)
            pageNumber = \(pageNumber)
            gridPosition = \(gridPosition)
            color = \(color)
            additionalOption = \(String(describing: additionalOptions))
            modname = \(modname)
            additionalInfo = \(additionalInfo)
            options = \(options)
            blocks = \(additionalInfo.blocks)
            name = \(additionalInfo.name)
            """
        }
    }
    
    public struct Connection {
        let sourceIndex: UInt32
        let sourceBlock: UInt32
        let destinationIndex: UInt32
        let destinationBlock: UInt32
        let connectionStrength: UInt32
    }
    
    public struct StarredElement {
        enum ElementType: Int {
            case parameter = 0
            case connection
        }
        
        let type: ElementType
        let moduleIndex: Int
        let inputBlockIndex: Int?
        let midiCCValue: Int
    }
    
    public let header: Header
    public let modules: [Module]
    public let connections: [Connection]
    public let pageNames: [String]
    public let starredElements: [StarredElement]?
    
    public var pages: [Module] {
        return modules.sorted {
            if $0.pageNumber == $1.pageNumber {
                return $0.gridPosition < $1.gridPosition
            } else {
                return $0.pageNumber < $1.pageNumber
            }
        }
    }
    
    public let isBuro = false
    
    public func module(at index: Int) -> [Module]? {
        return {
            var modules: [Module] = []
            for module in self.modules {
                if module.range.contains(index) {
                    modules.append(module)
                }
            }

            return modules.count > 0 ? modules : nil
        }()
    }
}

extension ZoiaFile {
    public enum Color: Int {
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

        public var value: UIColor {
            switch self {
            case .blue:
                return .blue
            case .green:
                return .green
            case .yellow:
                return .yellow
            case .aqua:
                return UIColor(red: 0, green: 255/255, blue: 255/255, alpha: 1)
            case .magenta:
                return .magenta
            case .orange:
                return .orange
            case .lime:
                return UIColor(red: 50/255, green: 205/255, blue: 50/255, alpha: 1)
            case .surf:
                return UIColor(red: 10/255, green: 255/255, blue: 100/255, alpha: 1)
            case .sky:
                return UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 1)
            case .purple:
                return .purple
            case .pink:
                return .systemPink
            case .peach:
                return UIColor(red: 255/255, green: 218/255, blue: 185/255, alpha: 1)
            case .mango:
                return UIColor(red: 244/255, green: 187/255, blue: 68/255, alpha: 1)
            default:
                return .white
            }
        }
    }
}


// TODO: Consider having this be the API for Modules?
public enum ModuleType: Int {
    case sv_filter = 0
    case audio_input
    case audio_output
    case aliaser
    case sequencer
    case lfo
    case adsr
    case vca
    case audio_multiply
    case bit_crusher
    case sample_and_hold = 10
    case od_and_distortion
    case env_follower
    case delay_line
    case oscillator
    case pushbutton
    case keyboard
    case cv_invert
    case steps
    case slew_limiter
    case midi_notes_in = 20
    case midi_cc_in
    case multiplier
    case compressor
    case multi_filter
    case plate_reverb
    case buffer_delay
    case all_pass_filter
    case quantizer
    case phaser
    case looper = 30
    case in_switch
    case out_switch
    case audio_in_switch
    case audio_out_switch
    case midi_pressure
    case onset_detector
    case rhythm
    case noise
    case random
    case gate = 40
    case tremolo
    case tone_control
    case delay_w_mod
    case stompswitch
    case value
    case cv_delay
    case cv_loop
    case cv_filter
    case clock_divider
    case comparator = 50
    case cv_rectify
    case trigger
    case stereo_spread
    case cport_exp_cv_in
    case cport_cv_out
    case ui_button
    case audio_panner
    case pitch_detector
    case pitch_shifter
    case midi_note_out = 60
    case midi_cc_out
    case midi_pc_out
    case bit_modulator
    case audio_balance
    case inverter
    case fuzz
    case ghostverb
    case cabinet_sim
    case flanger
    case chorus = 70
    case vibrato
    case env_filter
    case ring_modulator
    case hall_reverb
    case ping_pong_delay
    case audio_mixer
    case cv_flip_flop
    case diffuser
    case reverb_lite = 80
    case room_reverb
    case pixel
    case midi_clock_in
    case granular
    case midi_clock_out
    case tap_to_cv
    case midi_pitch_bend_in
    case euro_cv_out_4
    case euro_cv_in_1
    case euro_cv_in_2 = 90
    case euro_cv_in_3
    case euro_cv_in_4
    case euro_headphone_amp
    case euro_audio_input_1
    case euro_audio_input_2
    case euro_audio_output_1
    case euro_audio_output_2
    case euro_pushbutton_1
    case euro_pushbutton_2
    case euro_cv_out_1 = 100
    case euro_cv_out_2
    case euro_cv_out_3
    case sampler
    case device_control
    case cv_mixer
    
    private var index: Int {
        return self.rawValue
    }
    
    // TODO: start using this instead
    public var name: String {
        return ZoiaModuleInfoList[index].name
    }
    
    public var cpu: Double {
        return ZoiaModuleInfoList[index].cpu
    }
    
    var blocks: [ZoiaModuleInfoList.Block] {
        return ZoiaModuleInfoList[index].blocks
    }
    
    var minBlocks: Int {
        return ZoiaModuleInfoList[index].minBlocks
    }
    
    var maxBlocks: Int {
        return ZoiaModuleInfoList[index].maxBlocks
    }
    
    var description: String {
        let cleanedString = ZoiaModuleInfoList[index].description.replacingOccurrences(of: "\n\\s+", with: " ", options: .regularExpression)
        //cleanedString = ZoiaModuleInfoList[self.rawValue].description.replacingOccurrences(of: "(?m)^\\s+", with: "", options: .regularExpression)
        return String(cleanedString.dropFirst())
    }
    
    /// Get the options associated to this module. Every module can have a number of options.
    /// - Parameter module: The module to query.
    /// - Returns: Returns  the options un/set by the user.
    func options(for module: ZoiaFile.Module) -> [(module: [String: [ZoiaModuleInfoList.Option]], value: Any)] {
        let allOptions = ZoiaModuleInfoList[index].options
        
        var options: [(module: [String: [ZoiaModuleInfoList.Option]], value: Any)] = []
        for i in 0..<module.options.count {
            guard let optionValues = allOptions[i].values.first else { break }
            
            let selectedValue = optionValues[module.options[i]].value
            options.append((module: allOptions[i], value: selectedValue))
        }
        
        return options
    }
    
    func activeBlocks(for module: ZoiaFile.Module) -> [ZoiaModuleInfoList.Block] {
        // get the available blocks for this module. Combine this with the options Int array will indicate whether or not a block should be displayed.
        let blockList = self.blocks
        let options = self.options(for: module)
        var blocks: [ZoiaModuleInfoList.Block] = []
        
        precondition(!blockList.isEmpty, "There are no blocks for \(module)")
        
        let isOn: (String?) -> Bool = {
            return $0 == "on"
        }
        
        switch self {
        case .sv_filter:
            blocks += blockList[0...2]
            
            for (index, option) in options.enumerated() where isOn(option.value as? String) {
                blocks.append(blockList[index + 3])
            }
        
        case .audio_input:
            let channel = options.first?.value as? String
            switch channel {
            case "left":
                blocks.append(blockList[0])
            case "right":
                blocks.append(blockList[1])
            default:
                blocks += blockList[0...1]
            }
        
        case .audio_output:
            let channel = options.last?.value as? String
            switch channel {
            case "left":
                blocks.append(blockList[0])
            case "right":
                blocks.append(blockList[1])
            default:
                blocks += blockList[0...1]
            }
            
            if let gainControl = options.first?.value as? String, isOn(gainControl) {
                blocks.append(blockList[2])
            }
            // TODO: not seeing queue start in here
       
        case .sequencer:
            let numberOfSteps = (options.first?.value as? Int) ?? 1
            blocks += blockList[0..<numberOfSteps]
            
            if let restartJack = options[2].value as? String, isOn(restartJack) {
                blocks.append(blockList[33])
            }
            
            let numberOfTracks = options[1].value as? Int ?? 1
            blocks += blockList[34..<(numberOfTracks + 34)]
        
        case .lfo:
            if let input = (options.first?.value as? String), input == "tap" {
                blocks.append(blockList[0])
            } else {
                blocks.append(blockList[1])
            }
                 
            if let swingControl = options[1].value as? String, isOn(swingControl) {
                blocks.append(blockList[2])
            }
             
            if let phaseInput = options[2].value as? String, isOn(phaseInput) {
                blocks.append(blockList[3])
            }
            
            if let phaseReset = options[3].value as? String, isOn(phaseReset) {
                blocks.append(blockList[4])
            }
            
            blocks.append(blocks[5])
        
        case .adsr:
            blocks.append(blockList[0])
 
            if let retrigger = options[0].value as? String, isOn(retrigger) {
                blocks.append(blockList[1])
            }
            
            if let initialDelay = options[1].value as? String, isOn(initialDelay) {
                blocks.append(blockList[2])
            }
            
            if let str = options[3].value as? String, isOn(str) {
                blocks.append(blockList[6])
            }
            
            if let holdSustainRelease = options[5].value as? String, isOn(holdSustainRelease) {
                blocks.append(blockList[7])
            }
            
            if let str = options[3].value as? String, isOn(str) {
                blocks.append(blockList[8])
            }
            
            blocks.append(blockList[9])
        
        case .vca:
            blocks.append(blockList[0])

            if let channels = options[0].value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            blocks += blockList[2...3]
            
            if let channels = options[0].value as? String, channels == "stereo" {
                blocks.append(blockList[4])
            }
        
        case .env_follower:
            blocks.append(blockList[0])
            
            if let riseFall = options[0].value as? String, isOn(riseFall) {
                blocks += blockList[1...2]
            }
            
            blocks.append(blockList[3])
       
        case .delay_line:
            blocks.append(blockList[0])
            
            if let tapTempoIn = options[0].value as? String, tapTempoIn == "yes" {
                blocks += blockList[2...3]
            } else {
                blocks.append(blockList[1])
            }
            
            blocks.append(blockList[4])
       
        case .oscillator:
            blocks.append(blockList[0])
            
            if let fmIn = options[0].value as? String, isOn(fmIn) {
                blocks.append(blockList[1])
            }
            
            if let dutyCycle = options[1].value as? String, isOn(dutyCycle) {
                blocks.append(blockList[2])
            }
        
            blocks.append(blockList[3])
        
        case .keyboard:
            if let noteCount = options[0].value as? Int {
                blocks += blockList[0..<noteCount]
                blocks.append(blockList[32])
            }
            
            blocks += blockList[40...42]
        
        case .slew_limiter:
            blocks.append(blockList[0])
            
            if let control = options[0].value as? String, control == "linked" {
                blocks.append(blockList[1])
            } else {
                blocks += blockList[2...3]
            }
            
            blocks.append(blockList[4])
        
        case .midi_notes_in:
            let outputs = options[1].value as? Int ?? 1
            for i in 0..<outputs {
                blocks.append(blocks[4*i])
                blocks.append(blocks[4 * (1 + 1)])
                
                if let velocityOutput = options[0].value as? String, isOn(velocityOutput) {
                    blocks.append(blockList[4 * (i + 2)])
                }
                
                if let triggerPulse = options[0].value as? String, isOn(triggerPulse) {
                    blocks.append(blockList[4 * (i + 3)])
                }
            }
        
        case .multiplier:
            blocks.append(blockList[0])
            
            let outputCount = options[0].value as? Int ?? 1
            blocks += blockList[1..<outputCount]
            
            blocks.append(blockList[8])
        
        case .compressor:
            blocks.append(blockList[0])
            
            if let channels = options[3].value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            blocks.append(blockList[2])
            
            if let attackCTRL = options[0].value as? String, isOn(attackCTRL) {
                blocks.append(blockList[3])
            }
            
            if let releaseCTRL = options[1].value as? String, isOn(releaseCTRL) {
                blocks.append(blockList[4])
            }
            
            if let ratioCTRL = options[2].value as? String, isOn(ratioCTRL) {
                blocks.append(blockList[5])
            }
            
            if let sideChain = options[4].value as? String, sideChain == "external" {
                blocks.append(blockList[6])
            }
            
            blocks.append(blockList[7])
            
            if let channels = options[3].value as? String, channels == "stereo" {
                blocks.append(blockList[8])
            }
        
        case .multi_filter:
            blocks.append(blockList[0])
            
            if let filterShape = options[0].value as? String, ["bell","hi_shelf","low_shelf"].contains(filterShape) {
                blocks.append(blockList[1])
            }
            
            blocks += blockList[2...4]
        
        case .quantizer:
            blocks.append(blockList[0])
            if let keyScaleJacks = options.first?.value as? String, keyScaleJacks == "yes" {
                blocks += blockList[1...2]
            }
            
            blocks.append(blockList[3])
        
        case .phaser:
            blocks.append(blockList[0])
            
            if let channels = options[0].value as? String, channels == "2in->2out" {
                blocks.append(blockList[1])
            }
            
            let control = options[0].value as? String
            switch control {
            case "rate":
                blocks.append(blockList[2])
            case "tap_tempo":
                blocks.append(blockList[3])
            default:
                blocks.append(blockList[4])
            }
            
            blocks += blockList[5...8]
            
            if let channels = options[0].value as? String,channels == "1in->1out" {
                blocks.append(blockList[9])
            }
        
        case .looper:
            blocks = [blockList[0], blockList[1], blockList[2]]
            if let stopPlayButton = options[7].value as? String, stopPlayButton == "yes" {
                blocks.append(blockList[3])
            }
            
            blocks.append(blockList[4])
            
            if let lengthEdit = options[1].value as? String, isOn(lengthEdit) {
                blocks += blockList[5...6]
            }
            
            if let playReverse = options[5].value as? String, playReverse == "yes" {
                blocks.append(blockList[7])
            }
            
            if let overdub = options[6].value as? String, overdub == "overdub" {
                blocks.append(blockList[8])
            }
            blocks.append(blockList[9])
        
        case .in_switch:
            let inputs = options[0].value as? Int ?? 1
            blocks += blockList[0..<inputs]
            blocks += blockList[16...17]
        
        case .out_switch:
            blocks += blockList[0...1]
            let outputs = options[0].value as? Int ?? 1
            for i in 0..<outputs {
                blocks.append(blockList[i + 2])
            }
        
        case .audio_in_switch:
            let inputs = options[0].value as? Int ?? 0
            blocks += blockList[0...inputs]
            blocks += blockList[16...17]
        
        case .audio_out_switch:
            blocks = [blockList[0], blockList[1]]
            let outputs = options[0].value as? Int ?? 0
            for i in 0..<outputs {
                blocks.append(blockList[i + 2])
            }
        
        case .onset_detector:
            blocks = [blockList[0]]
            if let sensitivity = options[0].value as? String, isOn(sensitivity) {
                blocks.append(blockList[1])
            }
            
            blocks.append(blockList[2])
        
        case .rhythm:
            blocks = [blockList[0], blockList[1], blockList[2]]
            
            if let doneCTRL = options.first?.value as? String, isOn(doneCTRL){
                blocks.append(blockList[3])
            }
            
            blocks.append(blockList[4])
    
        case .random:
            if let newValOnTrig = options[1].value as? String, isOn(newValOnTrig) {
                blocks.append(blockList[0])
            }
            
            blocks.append(blockList[1])
            
        case .gate:
            blocks = [blockList[0]]

            if let channels = options[2].value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            blocks.append(blockList[2])

            if let attackCtrl = options[0].value as? String, isOn(attackCtrl) {
                blocks.append(blockList[3])
            }
            
            if let releaseCtrl = options[1].value as? String, isOn(releaseCtrl) {
                blocks.append(blockList[4])
            }
            
            if let sidechain = options[3].value as? String, sidechain == "external" {
                blocks.append(blockList[5])
            }
            
            blocks.append(blockList[6])
            
            if let channels = options[2].value as? String, channels == "stereo" {
                blocks.append(blockList[7])
            }
            
        case .tremolo:
            blocks = [blockList[0]]

            if let channels = options[0].value as? String, channels == "2in->2out" {
                blocks.append(blockList[1])
            }
            
            let control = options[1].value as? String
            switch control {
            case "rate":
                blocks.append(blockList[2])
            case "tap_tempo":
                blocks.append(blockList[3])
            default:
                blocks.append(blockList[4])
            }
            
            blocks += blockList[5...6]
            
            if let channels = options[0].value as? String, channels != "1in-1out" {
                blocks.append(blockList[7])
            }
            
        case .tone_control:
            blocks = [blockList[0]]
            if let channels = options[0].value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
        
            blocks += blockList[2...4]
            
            if let midBands = options[1].value as? Int, midBands == 2 {
                blocks += blockList[5...6]
            }
            
            blocks += blockList[7...8]
            
            if let channels = options[0].value as? String, channels == "stereo" {
                blocks.append(blockList[9])
            }
            
        case .delay_w_mod:
            blocks = [blockList[0]]
            if let channels = options[0].value as? String, channels == "2in->2out" {
                blocks.append(blockList[1])
            }
            
            if let control = options[1].value as? String, control == "rate" {
                blocks.append(blockList[2])
            } else {
                blocks.append(blockList[3])
            }
            
            blocks += blockList[4...8]
            
            if let channels = options[0].value as? String, channels != "1in->1out" {
                blocks.append(blockList[9])
            }
            
        case .cv_loop:
            blocks = [blockList[0], blockList[1], blockList[2], blockList[3]]
            if let length = options[1].value as? String, isOn(length) {
                blocks += blockList[4...5]
            }
            
            blocks += blockList[6...7]
            
        case .cv_filter:
            blocks = [blockList[0]]
            
            if let control = options[0].value as? String, control == "linked" {
                blocks.append(blockList[1])
            } else {
                blocks += blockList[2...3]
            }
            
            blocks.append(blockList[4])
            
        case .clock_divider:
            if module.version >= 1 {
                blocks = [blockList[0], blockList[1], blockList[3], blockList[4], blockList[5]]
            } else {
                blocks = [blockList[0], blockList[1], blockList[2], blockList[5]]
            }
            
        case .stereo_spread:
            if let haas = options.first?.value as? String, haas == "haas" {
                blocks = [blockList[0], blockList[3], blockList[4], blockList[5]]
            } else {
                blocks = [blockList[0], blockList[1], blockList[2], blockList[4], blockList[5]]
            }
        
        case .ui_button:
            blocks = [blockList[0]]
            
            if let cvOutput = options.first?.value as? String, cvOutput == "enabled" {
                blocks.append(blockList[1])
            }
            
        case .audio_panner:
            blocks = [blockList[0]]
            
            if let audioPanner = options.first?.value as? String, audioPanner == "2in->2out" {
                blocks.append(blockList[1])
            }

            blocks += blockList[2...4]
            
        case .midi_note_out:
            blocks = [blockList[0], blockList[1]]
            
            if let velocityOutput = options[1].value as? String, isOn(velocityOutput) {
                blocks.append(blockList[2])
            }
            
        case .audio_balance:
            if let stereo = options.first?.value as? String, stereo == "mono" {
                blocks = [blockList[0], blockList[2], blockList[4], blockList[5]]
            } else {
                blocks = blockList
            }
            
        case .ghostverb:
            blocks = [blockList[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            blocks += blockList[2...6]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                blocks.append(blockList[7])
            }
            
        case .cabinet_sim:
            if let channels = options.first?.value as? String, channels == "mono" {
                blocks = [blockList[0], blockList[2]]
            } else {
                blocks = blockList
            }
            
        case .flanger:
            blocks = [blockList[0]]
            if let channels = options.first?.value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            let control = options[1].value as? String
            switch control{
            case "rate":
                blocks.append(blockList[2])
            case "tap_tempo":
                blocks.append(blockList[3])
            default:
                blocks.append(blockList[4])
            }
            
            blocks += blockList[5...9]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                blocks.append(blockList[10])
            }
            
        case .chorus:
            blocks = [blockList[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            let control = options[1].value as? String
            switch control {
            case "rate":
                blocks.append(blockList[2])
            case "tap_tempo":
                blocks.append(blockList[3])
            default:
                blocks.append(blockList[4])
            }
            
            blocks += blockList[5...8]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                blocks.append(blockList[9])
            }
            
        case .vibrato:
            blocks = [blockList[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            let control = options[1].value as? String
            switch control {
            case "rate":
                blocks.append(blockList[2])
            case "tap_tempo":
                blocks.append(blockList[3])
            default:
                blocks.append(blockList[4])
            }
            
            blocks += blockList[5...6]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                blocks.append(blockList[7])
            }
            
        case .env_filter:
            blocks = [blockList[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            blocks += blockList[2...6]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                blocks.append(blockList[7])
            }
            
        case .ring_modulator:
            blocks = [blockList[0]]
            
            if let extAudioIn = options[1].value as? String, !isOn(extAudioIn) {
                blocks.append(blockList[1])
            } else {
                blocks.append(blockList[2])
            }
            
            if let dutyCycle =  options[2].value as? String, isOn(dutyCycle) {
                blocks.append(blockList[3])
            }
            
            blocks += blockList[4...5]

        case .ping_pong_delay:
            blocks = [blockList[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            if let control = options[1].value as? String, control == "rate" {
                blocks.append(blockList[2])
            } else {
                blocks.append(blockList[3])
            }
            
            blocks += blockList[4...9]
            
        case .audio_mixer:
            let channels = options.first?.value as? Int ?? 0
            
            for i in 0..<channels {
                blocks.append(blockList[2 * i])
                
                if let stereo = options[1].value as? String, stereo == "stereo" {
                    blocks.append(blockList[2 * i + 1])
                }
            }
            
            for i in 0..<channels {
                blocks.append(blockList[i + 15])
            }
            
            if let panning = options[2].value as? String, isOn(panning) {
                for i in 0...channels {
                    blocks.append(blockList[i + 23])
                }
            }
            
            blocks.append(blockList[32])
            
            if let stereo = options[1].value as? String, stereo == "stereo" {
                blocks.append(blockList[33])
            }
            
        case .reverb_lite:
            blocks = [blockList[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                blocks.append(blockList[1])
            }
            
            blocks += blockList[2...4]
            
            if let channels = options.first?.value as? String, channels != "1in->1out" {
                blocks.append(blockList[5])
            }
            
        case .pixel:
            if let cv = options.first?.value as? String, cv == "cv" {
                blocks = [blockList[0]]
            } else {
                blocks = [blockList[1]]
            }
            
        case .midi_clock_in:
            blocks = [blockList[0]]
            
            if let clockOut =
                options.first?.value as? String, clockOut == "enabled" {
                blocks.append(blockList[1])
            }
            
            if let runOut = options[1].value as? String, runOut == "enabled" {
                blocks.append(blockList[2])
            }
            
            if let divider = options[2].value as? String, divider == "enabled" {
                blocks.append(blockList[3])
            }
            
        case .granular:
            if let channels = options[1].value as? String, channels == "mono" {
                blocks = [blockList[0], blockList[2], blockList[3], blockList[4], blockList[5], blockList[6], blockList[7], blockList[8]]
            } else {
                blocks = blockList
            }
            
        case .midi_clock_out:
            blocks = [blockList[0]]
             
            if let runIn = options[1].value as? String, runIn == "enabled" {
                blocks.append(blockList[1])
            }
            
            if let resetIn = options[2].value as? String, resetIn == "enabled" {
                blocks.append(blockList[2])
            }
            
            if let position = options[3].value as? String, position == "enabled" {
                blocks += blockList[3...4]
            }
        
        case .tap_to_cv:
            blocks = [blockList[0]]
            
            if let range = options.first?.value as? String, isOn(range) {
                blocks += blockList[1...2]
            }
             
            blocks.append(blockList[3])
        
        case .sampler:
            blocks = [blockList[0]]
            
            if let record = options.first?.value as? String, record == "enabled" {
                blocks.append(blockList[1])
            }
            
            blocks += blockList[2...5]
            
            if let cvOutput = options[2].value as? String, isOn(cvOutput) {
                blocks.append(blockList[6])
            }
            
            blocks.append(blockList[7])
        
        case .device_control:
            let control = options.first?.value as? String
            switch control {
            case "bypass":
                blocks = [blockList[0]]
            case "stomp aux":
                blocks = [blockList[1]]
            default:
                blocks = [blockList[2]]
            }
        
        case .cv_mixer:
            let channels = options.first?.value as? Int ?? 0
            blocks += blockList[0..<channels]
            blocks += blockList[8..<(channels+8)]
            blocks.append(blockList[16])
           
        default:
            return blockList
        }
        
        return blocks
    }
}

extension Array {
    mutating func append(_ element: Element, onCondition: () -> Bool) {
        if onCondition() {
            self.append(element)
        }
    }
}
