//
//  ModuleType.swift
//
//
//  Created by Seth Howard on 12/4/23.
//

import Foundation

// Mark: - ModuleType
internal enum ModuleType: Int {
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
    case reverb_lite
    case room_reverb = 80
    case pixel
    case midi_clock_in
    case granular
    case midi_clock_out
    case tap_to_cv
    case midi_pitch_bend_in
    case euro_cv_out_4
    case euro_cv_in_1
    case euro_cv_in_2
    case euro_cv_in_3 = 90
    case euro_cv_in_4
    case euro_headphone_amp
    case euro_audio_input_1
    case euro_audio_input_2
    case euro_audio_output_1
    case euro_audio_output_2
    case euro_pushbutton_1
    case euro_pushbutton_2
    case euro_cv_out_1
    case euro_cv_out_2 = 100
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
    
    public var blocks: [BlockInfo] {
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
    func options(for module: Module) -> [(module: [String: [OptionInfo]], value: Any)] {
        let allOptions = ZoiaModuleInfoList[index].options
        
        var options: [(module: [String: [OptionInfo]], value: Any)] = []
        for i in 0..<module.options.count {
            guard i < allOptions.count, let optionValues = allOptions[i].values.first else { break }
            
            let selectedValue = optionValues[module.options[i]].value
            options.append((module: allOptions[i], value: selectedValue))
        }
        
        return options
    }
    
    func activeBlocks(for module: Module) -> [BlockInfo] {
        // get the available blocks for this module. Combine this with the options Int array will indicate whether or not a block should be displayed.
        let availableBlocks = self.blocks
        let options = self.options(for: module)
        var activeBlocks = [BlockInfo]()
        
        precondition(!availableBlocks.isEmpty, "There are no blocks for \(module)")
        
        let isOn: (String?) -> Bool = {
            return $0 == "on"
        }
        
        switch self {
        case .sv_filter:
            activeBlocks += availableBlocks[0...2]
            
            for (index, option) in options.enumerated() where isOn(option.value as? String) {
                activeBlocks.append(availableBlocks[index + 3])
            }
        
        case .audio_input:
            let channel = options.first?.value as? String
            switch channel {
            case "left":
                activeBlocks.append(availableBlocks[0])
            case "right":
                activeBlocks.append(availableBlocks[1])
            default:
                activeBlocks += availableBlocks[0...1]
            }
        
        case .audio_output:
            let channel = options.last?.value as? String
            switch channel {
            case "left":
                activeBlocks.append(availableBlocks[0])
            case "right":
                activeBlocks.append(availableBlocks[1])
            default:
                activeBlocks += availableBlocks[0...1]
            }
            
            if let gainControl = options.first?.value as? String, isOn(gainControl) {
                activeBlocks.append(availableBlocks[2])
            }
            // TODO: not seeing queue start in here
       
        case .sequencer:
            let numberOfSteps = (options.first?.value as? Int) ?? 1
            activeBlocks += availableBlocks[0..<numberOfSteps]
            
            if let restartJack = options[2].value as? String, isOn(restartJack) {
                activeBlocks.append(availableBlocks[33])
            }
            
            let numberOfTracks = options[1].value as? Int ?? 1
            activeBlocks += availableBlocks[34..<(numberOfTracks + 34)]
        
        case .lfo:
            if let input = (options.first?.value as? String), input == "tap" {
                activeBlocks.append(availableBlocks[0])
            } else {
                activeBlocks.append(availableBlocks[1])
            }
                 
            if let swingControl = options[1].value as? String, isOn(swingControl) {
                activeBlocks.append(availableBlocks[2])
            }
             
            if let phaseInput = options[2].value as? String, isOn(phaseInput) {
                activeBlocks.append(availableBlocks[3])
            }
            
            if let phaseReset = options[3].value as? String, isOn(phaseReset) {
                activeBlocks.append(availableBlocks[4])
            }
            
            activeBlocks.append(availableBlocks[5])
        
        case .adsr:
            activeBlocks.append(availableBlocks[0])
 
            if let retrigger = options[0].value as? String, isOn(retrigger) {
                activeBlocks.append(availableBlocks[1])
            }
            
            if let initialDelay = options[1].value as? String, isOn(initialDelay) {
                activeBlocks.append(availableBlocks[2])
            }
            
            if let str = options[3].value as? String, isOn(str) {
                activeBlocks.append(availableBlocks[6])
            }
            
            if let holdSustainRelease = options[5].value as? String, isOn(holdSustainRelease) {
                activeBlocks.append(availableBlocks[7])
            }
            
            if let str = options[3].value as? String, isOn(str) {
                activeBlocks.append(availableBlocks[8])
            }
            
            activeBlocks.append(availableBlocks[9])
        
        case .vca:
            activeBlocks.append(availableBlocks[0])

            if let channels = options[0].value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks += availableBlocks[2...3]
            
            if let channels = options[0].value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[4])
            }
        
        case .env_follower:
            activeBlocks.append(availableBlocks[0])
            
            if let riseFall = options[0].value as? String, isOn(riseFall) {
                activeBlocks += availableBlocks[1...2]
            }
            
            activeBlocks.append(availableBlocks[3])
       
        case .delay_line:
            activeBlocks.append(availableBlocks[0])
            
            if let tapTempoIn = options[0].value as? String, tapTempoIn == "yes" {
                activeBlocks += availableBlocks[2...3]
            } else {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks.append(availableBlocks[4])
       
        case .oscillator:
            activeBlocks.append(availableBlocks[0])
            
            if let fmIn = options[0].value as? String, isOn(fmIn) {
                activeBlocks.append(availableBlocks[1])
            }
            
            if let dutyCycle = options[1].value as? String, isOn(dutyCycle) {
                activeBlocks.append(availableBlocks[2])
            }
        
            activeBlocks.append(availableBlocks[3])
        
        case .keyboard:
            if let noteCount = options[0].value as? Int {
                activeBlocks += availableBlocks[0..<noteCount]
                activeBlocks.append(availableBlocks[32])
            }
            
            activeBlocks += availableBlocks[40...42]
        
        case .slew_limiter:
            activeBlocks.append(availableBlocks[0])
            
            if let control = options[0].value as? String, control == "linked" {
                activeBlocks.append(availableBlocks[1])
            } else {
                activeBlocks += availableBlocks[2...3]
            }
            
            activeBlocks.append(availableBlocks[4])
        
        case .midi_notes_in:
            let outputs = options[1].value as? Int ?? 1
            for i in 0..<outputs {
                activeBlocks.append(activeBlocks[4*i])
                activeBlocks.append(activeBlocks[4 * (1 + 1)])
                
                if let velocityOutput = options[0].value as? String, isOn(velocityOutput) {
                    activeBlocks.append(availableBlocks[4 * (i + 2)])
                }
                
                if let triggerPulse = options[0].value as? String, isOn(triggerPulse) {
                    activeBlocks.append(availableBlocks[4 * (i + 3)])
                }
            }
        
        case .multiplier:
            activeBlocks.append(availableBlocks[0])
            
            let outputCount = options[0].value as? Int ?? 1
            activeBlocks += availableBlocks[1..<outputCount]
            
            activeBlocks.append(availableBlocks[8])
        
        case .compressor:
            activeBlocks.append(availableBlocks[0])
            
            if let channels = options[3].value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks.append(availableBlocks[2])
            
            if let attackCTRL = options[0].value as? String, isOn(attackCTRL) {
                activeBlocks.append(availableBlocks[3])
            }
            
            if let releaseCTRL = options[1].value as? String, isOn(releaseCTRL) {
                activeBlocks.append(availableBlocks[4])
            }
            
            if let ratioCTRL = options[2].value as? String, isOn(ratioCTRL) {
                activeBlocks.append(availableBlocks[5])
            }
            
            if let sideChain = options[4].value as? String, sideChain == "external" {
                activeBlocks.append(availableBlocks[6])
            }
            
            activeBlocks.append(availableBlocks[7])
            
            if let channels = options[3].value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[8])
            }
        
        case .multi_filter:
            activeBlocks.append(availableBlocks[0])
            
            if let filterShape = options[0].value as? String, ["bell","hi_shelf","low_shelf"].contains(filterShape) {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks += availableBlocks[2...4]
        
        case .quantizer:
            activeBlocks.append(availableBlocks[0])
            if let keyScaleJacks = options.first?.value as? String, keyScaleJacks == "yes" {
                activeBlocks += availableBlocks[1...2]
            }
            
            activeBlocks.append(availableBlocks[3])
        
        case .phaser:
            activeBlocks.append(availableBlocks[0])
            
            if let channels = options[0].value as? String, channels == "2in->2out" {
                activeBlocks.append(availableBlocks[1])
            }
            
            let control = options[0].value as? String
            switch control {
            case "rate":
                activeBlocks.append(availableBlocks[2])
            case "tap_tempo":
                activeBlocks.append(availableBlocks[3])
            default:
                activeBlocks.append(availableBlocks[4])
            }
            
            activeBlocks += availableBlocks[5...8]
            
            if let channels = options[0].value as? String,channels == "1in->1out" {
                activeBlocks.append(availableBlocks[9])
            }
        
        case .looper:
            activeBlocks = [availableBlocks[0], availableBlocks[1], availableBlocks[2]]
            if let stopPlayButton = options[7].value as? String, stopPlayButton == "yes" {
                activeBlocks.append(availableBlocks[3])
            }
            
            activeBlocks.append(availableBlocks[4])
            
            if let lengthEdit = options[1].value as? String, isOn(lengthEdit) {
                activeBlocks += availableBlocks[5...6]
            }
            
            if let playReverse = options[5].value as? String, playReverse == "yes" {
                activeBlocks.append(availableBlocks[7])
            }
            
            if let overdub = options[6].value as? String, overdub == "overdub" {
                activeBlocks.append(availableBlocks[8])
            }
            activeBlocks.append(availableBlocks[9])
        
        case .in_switch:
            let inputs = options[0].value as? Int ?? 1
            activeBlocks += availableBlocks[0..<inputs]
            activeBlocks += availableBlocks[16...17]
        
        case .out_switch:
            activeBlocks += availableBlocks[0...1]
            let outputs = options[0].value as? Int ?? 1
            for i in 0..<outputs {
                activeBlocks.append(availableBlocks[i + 2])
            }
        
        case .audio_in_switch:
            let inputs = options[0].value as? Int ?? 0
            activeBlocks += availableBlocks[0...inputs]
            activeBlocks += availableBlocks[16...17]
        
        case .audio_out_switch:
            activeBlocks = [availableBlocks[0], availableBlocks[1]]
            let outputs = options[0].value as? Int ?? 0
            for i in 0..<outputs {
                activeBlocks.append(availableBlocks[i + 2])
            }
        
        case .onset_detector:
            activeBlocks = [availableBlocks[0]]
            if let sensitivity = options[0].value as? String, isOn(sensitivity) {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks.append(availableBlocks[2])
        
        case .rhythm:
            activeBlocks = [availableBlocks[0], availableBlocks[1], availableBlocks[2]]
            
            if let doneCTRL = options.first?.value as? String, isOn(doneCTRL){
                activeBlocks.append(availableBlocks[3])
            }
            
            activeBlocks.append(availableBlocks[4])
    
        case .random:
            if let newValOnTrig = options[1].value as? String, isOn(newValOnTrig) {
                activeBlocks.append(availableBlocks[0])
            }
            
            activeBlocks.append(availableBlocks[1])
            
        case .gate:
            activeBlocks = [availableBlocks[0]]

            if let channels = options[2].value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks.append(availableBlocks[2])

            if let attackCtrl = options[0].value as? String, isOn(attackCtrl) {
                activeBlocks.append(availableBlocks[3])
            }
            
            if let releaseCtrl = options[1].value as? String, isOn(releaseCtrl) {
                activeBlocks.append(availableBlocks[4])
            }
            
            if let sidechain = options[3].value as? String, sidechain == "external" {
                activeBlocks.append(availableBlocks[5])
            }
            
            activeBlocks.append(availableBlocks[6])
            
            if let channels = options[2].value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[7])
            }
            
        case .tremolo:
            activeBlocks = [availableBlocks[0]]

            if let channels = options[0].value as? String, channels == "2in->2out" {
                activeBlocks.append(availableBlocks[1])
            }
            
            let control = options[1].value as? String
            switch control {
            case "rate":
                activeBlocks.append(availableBlocks[2])
            case "tap_tempo":
                activeBlocks.append(availableBlocks[3])
            default:
                activeBlocks.append(availableBlocks[4])
            }
            
            activeBlocks += availableBlocks[5...6]
            
            if let channels = options[0].value as? String, channels != "1in-1out" {
                activeBlocks.append(availableBlocks[7])
            }
            
        case .tone_control:
            activeBlocks = [availableBlocks[0]]
            if let channels = options[0].value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
        
            activeBlocks += availableBlocks[2...4]
            
            if let midBands = options[1].value as? Int, midBands == 2 {
                activeBlocks += availableBlocks[5...6]
            }
            
            activeBlocks += availableBlocks[7...8]
            
            if let channels = options[0].value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[9])
            }
            
        case .delay_w_mod:
            activeBlocks = [availableBlocks[0]]
            if let channels = options[0].value as? String, channels == "2in->2out" {
                activeBlocks.append(availableBlocks[1])
            }
            
            if let control = options[1].value as? String, control == "rate" {
                activeBlocks.append(availableBlocks[2])
            } else {
                activeBlocks.append(availableBlocks[3])
            }
            
            activeBlocks += availableBlocks[4...8]
            
            if let channels = options[0].value as? String, channels != "1in->1out" {
                activeBlocks.append(availableBlocks[9])
            }
            
        case .cv_loop:
            activeBlocks = [availableBlocks[0], availableBlocks[1], availableBlocks[2], availableBlocks[3]]
            if let length = options[1].value as? String, isOn(length) {
                activeBlocks += availableBlocks[4...5]
            }
            
            activeBlocks += availableBlocks[6...7]
            
        case .cv_filter:
            activeBlocks = [availableBlocks[0]]
            
            if let control = options[0].value as? String, control == "linked" {
                activeBlocks.append(availableBlocks[1])
            } else {
                activeBlocks += availableBlocks[2...3]
            }
            
            activeBlocks.append(availableBlocks[4])
            
        case .clock_divider:
            if module.version >= 1 {
                activeBlocks = [availableBlocks[0], availableBlocks[1], availableBlocks[3], availableBlocks[4], availableBlocks[5]]
            } else {
                activeBlocks = [availableBlocks[0], availableBlocks[1], availableBlocks[2], availableBlocks[5]]
            }
            
        case .stereo_spread:
            if let haas = options.first?.value as? String, haas == "haas" {
                activeBlocks = [availableBlocks[0], availableBlocks[3], availableBlocks[4], availableBlocks[5]]
            } else {
                activeBlocks = [availableBlocks[0], availableBlocks[1], availableBlocks[2], availableBlocks[4], availableBlocks[5]]
            }
        
        case .ui_button:
            activeBlocks = [availableBlocks[0]]
            
            if let cvOutput = options.first?.value as? String, cvOutput == "enabled" {
                activeBlocks.append(availableBlocks[1])
            }
            
        case .audio_panner:
            activeBlocks = [availableBlocks[0]]
            
            if let audioPanner = options.first?.value as? String, audioPanner == "2in->2out" {
                activeBlocks.append(availableBlocks[1])
            }

            activeBlocks += availableBlocks[2...4]
            
        case .midi_note_out:
            activeBlocks = [availableBlocks[0], availableBlocks[1]]
            
            if let velocityOutput = options[1].value as? String, isOn(velocityOutput) {
                activeBlocks.append(availableBlocks[2])
            }
            
        case .audio_balance:
            if let stereo = options.first?.value as? String, stereo == "mono" {
                activeBlocks = [availableBlocks[0], availableBlocks[2], availableBlocks[4], availableBlocks[5]]
            } else {
                activeBlocks = availableBlocks
            }
            
        case .ghostverb:
            activeBlocks = [availableBlocks[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks += availableBlocks[2...6]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                activeBlocks.append(availableBlocks[7])
            }
            
        case .cabinet_sim:
            if let channels = options.first?.value as? String, channels == "mono" {
                activeBlocks = [availableBlocks[0], availableBlocks[2]]
            } else {
                activeBlocks = availableBlocks
            }
            
        case .flanger:
            activeBlocks = [availableBlocks[0]]
            if let channels = options.first?.value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            let control = options[1].value as? String
            switch control{
            case "rate":
                activeBlocks.append(availableBlocks[2])
            case "tap_tempo":
                activeBlocks.append(availableBlocks[3])
            default:
                activeBlocks.append(availableBlocks[4])
            }
            
            activeBlocks += availableBlocks[5...9]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                activeBlocks.append(availableBlocks[10])
            }
            
        case .chorus:
            activeBlocks = [availableBlocks[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            let control = options[1].value as? String
            switch control {
            case "rate":
                activeBlocks.append(availableBlocks[2])
            case "tap_tempo":
                activeBlocks.append(availableBlocks[3])
            default:
                activeBlocks.append(availableBlocks[4])
            }
            
            activeBlocks += availableBlocks[5...8]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                activeBlocks.append(availableBlocks[9])
            }
            
        case .vibrato:
            activeBlocks = [availableBlocks[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            let control = options[1].value as? String
            switch control {
            case "rate":
                activeBlocks.append(availableBlocks[2])
            case "tap_tempo":
                activeBlocks.append(availableBlocks[3])
            default:
                activeBlocks.append(availableBlocks[4])
            }
            
            activeBlocks += availableBlocks[5...6]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                activeBlocks.append(availableBlocks[7])
            }
            
        case .env_filter:
            activeBlocks = [availableBlocks[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks += availableBlocks[2...6]
            
            if let channels = options.first?.value as? String, channels != "1in>1out" {
                activeBlocks.append(availableBlocks[7])
            }
            
        case .ring_modulator:
            activeBlocks = [availableBlocks[0]]
            
            if let extAudioIn = options[1].value as? String, !isOn(extAudioIn) {
                activeBlocks.append(availableBlocks[1])
            } else {
                activeBlocks.append(availableBlocks[2])
            }
            
            if let dutyCycle =  options[2].value as? String, isOn(dutyCycle) {
                activeBlocks.append(availableBlocks[3])
            }
            
            activeBlocks += availableBlocks[4...5]

        case .ping_pong_delay:
            activeBlocks = [availableBlocks[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            if let control = options[1].value as? String, control == "rate" {
                activeBlocks.append(availableBlocks[2])
            } else {
                activeBlocks.append(availableBlocks[3])
            }
            
            activeBlocks += availableBlocks[4...9]
            
        case .audio_mixer:
            let channels = options.first?.value as? Int ?? 0
            
            for i in 0..<channels {
                activeBlocks.append(availableBlocks[2 * i])
                
                if let stereo = options[1].value as? String, stereo == "stereo" {
                    activeBlocks.append(availableBlocks[2 * i + 1])
                }
            }
            
            for i in 0..<channels {
                activeBlocks.append(availableBlocks[i + 15])
            }
            
            if let panning = options[2].value as? String, isOn(panning) {
                for i in 0...channels {
                    activeBlocks.append(availableBlocks[i + 23])
                }
            }
            
            activeBlocks.append(availableBlocks[32])
            
            if let stereo = options[1].value as? String, stereo == "stereo" {
                activeBlocks.append(availableBlocks[33])
            }
            
        case .reverb_lite:
            activeBlocks = [availableBlocks[0]]
            
            if let channels = options.first?.value as? String, channels == "stereo" {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks += availableBlocks[2...4]
            
            if let channels = options.first?.value as? String, channels != "1in->1out" {
                activeBlocks.append(availableBlocks[5])
            }
            
        case .pixel:
            if let cv = options.first?.value as? String, cv == "cv" {
                activeBlocks = [availableBlocks[0]]
            } else {
                activeBlocks = [availableBlocks[1]]
            }
            
        case .midi_clock_in:
            activeBlocks = [availableBlocks[0]]
            
            if let clockOut =
                options.first?.value as? String, clockOut == "enabled" {
                activeBlocks.append(availableBlocks[1])
            }
            
            if let runOut = options[1].value as? String, runOut == "enabled" {
                activeBlocks.append(availableBlocks[2])
            }
            
            if let divider = options[2].value as? String, divider == "enabled" {
                activeBlocks.append(availableBlocks[3])
            }
            
        case .granular:
            if let channels = options[1].value as? String, channels == "mono" {
                activeBlocks = [availableBlocks[0], availableBlocks[2], availableBlocks[3], availableBlocks[4], availableBlocks[5], availableBlocks[6], availableBlocks[7], availableBlocks[8]]
            } else {
                activeBlocks = availableBlocks
            }
            
        case .midi_clock_out:
            activeBlocks = [availableBlocks[0]]
             
            if let runIn = options[1].value as? String, runIn == "enabled" {
                activeBlocks.append(availableBlocks[1])
            }
            
            if let resetIn = options[2].value as? String, resetIn == "enabled" {
                activeBlocks.append(availableBlocks[2])
            }
            
            if let position = options[3].value as? String, position == "enabled" {
                activeBlocks += availableBlocks[3...4]
            }
        
        case .tap_to_cv:
            activeBlocks = [availableBlocks[0]]
            
            if let range = options.first?.value as? String, isOn(range) {
                activeBlocks += availableBlocks[1...2]
            }
             
            activeBlocks.append(availableBlocks[3])
        
        case .sampler:
            activeBlocks = [availableBlocks[0]]
            
            if let record = options.first?.value as? String, record == "enabled" {
                activeBlocks.append(availableBlocks[1])
            }
            
            activeBlocks += availableBlocks[2...5]
            
            if let cvOutput = options[2].value as? String, isOn(cvOutput) {
                activeBlocks.append(availableBlocks[6])
            }
            
            activeBlocks.append(availableBlocks[7])
        
        case .device_control:
            let control = options.first?.value as? String
            switch control {
            case "bypass":
                activeBlocks = [availableBlocks[0]]
            case "stomp aux":
                activeBlocks = [availableBlocks[1]]
            default:
                activeBlocks = [availableBlocks[2]]
            }
        
        case .cv_mixer:
            let channels = options.first?.value as? Int ?? 0
            activeBlocks += availableBlocks[0..<channels]
            activeBlocks += availableBlocks[8..<(channels+8)]
            activeBlocks.append(availableBlocks[16])
           
        default:
            return availableBlocks
        }
        
        return activeBlocks
    }
}
