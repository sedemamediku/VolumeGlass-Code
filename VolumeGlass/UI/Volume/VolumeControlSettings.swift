import Foundation
import SwiftUI
import Combine

enum AnimationSpeed: String, CaseIterable {
    case fast = "Fast"
    case normal = "Normal"
    case slow = "Slow"
    
    var springResponse: Double {
        switch self {
        case .fast: return 0.25
        case .normal: return 0.35
        case .slow: return 0.5
        }
    }
    
    var springDamping: Double {
        switch self {
        case .fast: return 0.7
        case .normal: return 0.75
        case .slow: return 0.8
        }
    }
}

enum VolumeDisplayStyle: String, CaseIterable {
    case current = "Dark"
    case liquidGlass = "Light"
}

class VolumeControlSettings: ObservableObject {
    // Volume control settings
    @Published var volumeStep: Float = 0.05 {
        didSet { save() }
    }
    
    @Published var hapticFeedbackEnabled: Bool = true {
        didSet { save() }
    }
    
    @Published var visibilityTimeout: TimeInterval = 2.0 {
        didSet { save() }
    }
    
    @Published var customPresets: [Float] = [0.25, 0.5, 0.75, 1.0] {
        didSet { save() }
    }
    
    @Published var animationSpeed: AnimationSpeed = .normal {
        didSet { save() }
    }
    
    @Published var showDragHandle: Bool = true {
        didSet { save() }
    }
    
    @Published var displayStyle: VolumeDisplayStyle = .current {
        didSet { save() }
    }
    
    // Advanced settings
    @Published var volumeHighThreshold: Float = 0.66 {
        didSet { save() }
    }
    
    @Published var volumeMediumThreshold: Float = 0.33 {
        didSet { save() }
    }
    
    @Published var hoverDelay: TimeInterval = 0.5 {
        didSet { save() }
    }
    
    init() {
        load()
    }
    
    private func save() {
        UserDefaults.standard.set(volumeStep, forKey: "volumeStep")
        UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        UserDefaults.standard.set(visibilityTimeout, forKey: "visibilityTimeout")
        UserDefaults.standard.set(customPresets.map { Double($0) }, forKey: "customPresets")
        UserDefaults.standard.set(animationSpeed.rawValue, forKey: "animationSpeed")
        UserDefaults.standard.set(showDragHandle, forKey: "showDragHandle")
        UserDefaults.standard.set(displayStyle.rawValue, forKey: "displayStyle")
        UserDefaults.standard.set(volumeHighThreshold, forKey: "volumeHighThreshold")
        UserDefaults.standard.set(volumeMediumThreshold, forKey: "volumeMediumThreshold")
        UserDefaults.standard.set(hoverDelay, forKey: "hoverDelay")
    }
    
    private func load() {
        if let savedStep = UserDefaults.standard.object(forKey: "volumeStep") as? Float {
            volumeStep = savedStep
        }
        
        hapticFeedbackEnabled = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
        
        if let savedTimeout = UserDefaults.standard.object(forKey: "visibilityTimeout") as? TimeInterval {
            visibilityTimeout = savedTimeout
        }
        
        if let savedPresets = UserDefaults.standard.array(forKey: "customPresets") as? [Double] {
            customPresets = savedPresets.map { Float($0) }
        }
        
        if let savedSpeed = UserDefaults.standard.string(forKey: "animationSpeed"),
           let speed = AnimationSpeed(rawValue: savedSpeed) {
            animationSpeed = speed
        }
        
        showDragHandle = UserDefaults.standard.object(forKey: "showDragHandle") as? Bool ?? true
        
        if let savedStyle = UserDefaults.standard.string(forKey: "displayStyle") {
            // Handle migration from old values
            if savedStyle == "Current" {
                displayStyle = .current
            } else if savedStyle == "Liquid Glass" {
                displayStyle = .liquidGlass
            } else if let style = VolumeDisplayStyle(rawValue: savedStyle) {
                displayStyle = style
            }
        }
        
        if let savedHigh = UserDefaults.standard.object(forKey: "volumeHighThreshold") as? Float {
            volumeHighThreshold = savedHigh
        }
        
        if let savedMedium = UserDefaults.standard.object(forKey: "volumeMediumThreshold") as? Float {
            volumeMediumThreshold = savedMedium
        }
        
        if let savedDelay = UserDefaults.standard.object(forKey: "hoverDelay") as? TimeInterval {
            hoverDelay = savedDelay
        }
    }
    
    func resetToDefaults() {
        volumeStep = 0.05
        hapticFeedbackEnabled = true
        visibilityTimeout = 2.0
        customPresets = [0.25, 0.5, 0.75, 1.0]
        animationSpeed = .normal
        showDragHandle = true
        displayStyle = .current
        volumeHighThreshold = 0.66
        volumeMediumThreshold = 0.33
        hoverDelay = 0.5
    }
}

