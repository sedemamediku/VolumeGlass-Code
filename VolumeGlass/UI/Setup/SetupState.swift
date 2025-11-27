import Foundation
import SwiftUI
import Combine

enum VolumeBarPosition: CaseIterable {
    case leftMiddleVertical
    case bottomVertical
    case rightVertical
    case topHorizontal
    case bottomHorizontal
    case custom
  
    var displayName: String {
        switch self {
        case .leftMiddleVertical: return "Left Middle (Vertical)"
        case .bottomVertical: return "Bottom (Vertical)"
        case .rightVertical: return "Right (Vertical)"
        case .topHorizontal: return "Top (Horizontal)"
        case .bottomHorizontal: return "Bottom (Horizontal)"
        case .custom: return "Custom (Draggable)"
        }
    }
  
    var isVertical: Bool {
        switch self {
        case .leftMiddleVertical, .bottomVertical, .rightVertical:
            return true
        case .topHorizontal, .bottomHorizontal:
            return false
        case .custom:
            return true // Default to vertical for custom
        }
    }
  
    func getScreenPosition(screenFrame: NSRect, barSize: CGFloat) -> NSRect {
        let windowWidth = isVertical ? CGFloat(50 * barSize) : CGFloat(240 * barSize)
        let windowHeight = isVertical ? CGFloat(240 * barSize) : CGFloat(50 * barSize)
      
        let padding: CGFloat = 40
      
        switch self {
        case .leftMiddleVertical:
            return NSRect(
                x: screenFrame.origin.x + padding,
                y: screenFrame.origin.y + (screenFrame.height / 2) - (windowHeight / 2),
                width: windowWidth,
                height: windowHeight
            )
        case .bottomVertical:
            return NSRect(
                x: screenFrame.origin.x + (screenFrame.width / 2) - (windowWidth / 2),
                y: screenFrame.origin.y + padding,
                width: windowWidth,
                height: windowHeight
            )
        case .rightVertical:
            return NSRect(
                x: screenFrame.origin.x + screenFrame.width - windowWidth - padding,
                y: screenFrame.origin.y + (screenFrame.height / 2) - (windowHeight / 2),
                width: windowWidth,
                height: windowHeight
            )
        case .topHorizontal:
            return NSRect(
                x: screenFrame.origin.x + (screenFrame.width / 2) - (windowWidth / 2),
                y: screenFrame.origin.y + screenFrame.height - windowHeight - padding,
                width: windowWidth,
                height: windowHeight
            )
        case .bottomHorizontal:
            return NSRect(
                x: screenFrame.origin.x + (screenFrame.width / 2) - (windowWidth / 2),
                y: screenFrame.origin.y + padding,
                width: windowWidth,
                height: windowHeight
            )
        case .custom:
            // Custom position will be loaded from UserDefaults
            // Default to center if not set
            return NSRect(
                x: screenFrame.origin.x + (screenFrame.width / 2) - (windowWidth / 2),
                y: screenFrame.origin.y + (screenFrame.height / 2) - (windowHeight / 2),
                width: windowWidth,
                height: windowHeight
            )
        }
    }
}

class SetupState: ObservableObject {
    @Published var selectedPosition: VolumeBarPosition = .leftMiddleVertical
    @Published var barSize: CGFloat = AppConstants.defaultBarSize
    @Published var isSetupComplete: Bool
    
    // Custom position storage (relative to screen)
    @Published var customPositionX: CGFloat?
    @Published var customPositionY: CGFloat?

    init() {
        // Force walkthrough to always show during testing
        UserDefaults.standard.set(false, forKey: "isSetupComplete")

        isSetupComplete = UserDefaults.standard.bool(forKey: "isSetupComplete")
    
        if let savedPositionRaw = UserDefaults.standard.string(forKey: "volumeBarPosition"),
           let savedPosition = VolumeBarPosition.allCases.first(where: { $0.displayName == savedPositionRaw }) {
            self.selectedPosition = savedPosition
        }
    
        let savedSize = UserDefaults.standard.double(forKey: "barSize")
        if savedSize > 0 {
            self.barSize = CGFloat(savedSize)
        }
        
        // Load custom position if it exists
        let savedCustomX = UserDefaults.standard.double(forKey: "customPositionX")
        let savedCustomY = UserDefaults.standard.double(forKey: "customPositionY")
        if savedCustomX > 0 && savedCustomY > 0 {
            self.customPositionX = CGFloat(savedCustomX)
            self.customPositionY = CGFloat(savedCustomY)
        }
    }
  
    func completeSetup() {
        UserDefaults.standard.set(true, forKey: "isSetupComplete")
        UserDefaults.standard.set(selectedPosition.displayName, forKey: "volumeBarPosition")
        UserDefaults.standard.set(Double(barSize), forKey: "barSize")
        
        // Save custom position if set
        if let customX = customPositionX, let customY = customPositionY {
            UserDefaults.standard.set(Double(customX), forKey: "customPositionX")
            UserDefaults.standard.set(Double(customY), forKey: "customPositionY")
        }
    
        isSetupComplete = true
    
        NotificationHelper.postSetupComplete()
    }
    
    func saveCustomPosition(x: CGFloat, y: CGFloat) {
        customPositionX = x
        customPositionY = y
        UserDefaults.standard.set(Double(x), forKey: "customPositionX")
        UserDefaults.standard.set(Double(y), forKey: "customPositionY")
    }
}

