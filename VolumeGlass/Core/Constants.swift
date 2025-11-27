import Foundation
import AppKit

/// Centralized constants used throughout the application
enum AppConstants {
    // Window dimensions
    static let setupWindowWidth: CGFloat = 900
    static let setupWindowHeight: CGFloat = 800
    
    // Volume control
    static let defaultVolume: Float = 0.5
    static let volumeStep: Float = 0.05
    static let volumeChangeTimeout: TimeInterval = 2.0
    static let volumePresets: [Float] = [0.25, 0.5, 0.75, 1.0]
    
    // Volume thresholds for icon display
    static let volumeHighThreshold: Float = 0.66
    static let volumeMediumThreshold: Float = 0.33
    
    // UI dimensions
    static let volumeBarWidth: CGFloat = 60
    static let volumeBarHeight: CGFloat = 280
    static let windowExpansionWidth: CGFloat = 520  // Increased to accommodate menu + side panel + close button with padding
    static let windowExpansionHeight: CGFloat = 60
    static let windowPadding: CGFloat = 30
    static let sliderAreaWidth: CGFloat = 120
    
    // Animation timings
    static let quickAnimationDuration: TimeInterval = 0.1
    static let standardAnimationDuration: TimeInterval = 0.2
    static let fadeOutAnimationDuration: TimeInterval = 0.4
    static let hoverDelay: TimeInterval = 0.5
    static let visibilityTimeout: TimeInterval = 2.0
    static let visibilityTimeoutAfterHover: TimeInterval = 1.0
    static let dragEndTimeout: TimeInterval = 1.5
    static let windowOrderCheckInterval: TimeInterval = 0.5
    static let setupCompleteDelay: TimeInterval = 0.5
    
    // Update checking
    static let updateCheckInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    static let updateCheckDelay: TimeInterval = 2.0
    
    // Gesture timings
    static let longPressDuration: TimeInterval = 0.8
    static let pressAnimationDelay: TimeInterval = 0.1
    
    // Bar size constraints
    static let minBarSize: CGFloat = 0.5
    static let maxBarSize: CGFloat = 2.0
    static let defaultBarSize: CGFloat = 1.0
    
    // Position detection
    static let rightSideThreshold: CGFloat = 0.6 // 60% of screen width
    
    // Volume bar dimensions (base)
    static let baseBarWidth: CGFloat = 12
    static let expandedBarWidth: CGFloat = 18
    static let baseBarHeight: CGFloat = 220
    static let cornerRadiusMultiplier: CGFloat = 9
    
    // Hover zone dimensions
    static let hoverZoneExtension: CGFloat = 80
    
    // UI opacity values
    static let primaryOpacityHigh: Double = 0.95
    static let primaryOpacityMedium: Double = 0.8
    static let primaryOpacityLow: Double = 0.6
    static let primaryOpacityVeryLow: Double = 0.5
    static let backgroundOpacity: Double = 0.3
    static let materialOpacity: Double = 0.6
    
    // Preview dimensions
    static let previewWidth: CGFloat = 400
    static let previewHeight: CGFloat = 250
    static let previewVolume: CGFloat = 0.6
}

