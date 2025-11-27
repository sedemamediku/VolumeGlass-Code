import Foundation

/// Utility class for posting common notifications throughout the application
struct NotificationHelper {
    /// Posts a volume bar visibility change notification
    static func postVolumeBarVisibilityChanged(isVisible: Bool) {
        NotificationCenter.default.post(
            name: NotificationNames.volumeBarVisibilityChanged,
            object: nil,
            userInfo: ["isVisible": isVisible]
        )
    }
    
    /// Posts a quick actions state change notification
    static func postQuickActionsStateChanged(isOpen: Bool) {
        NotificationCenter.default.post(
            name: NotificationNames.quickActionsStateChanged,
            object: nil,
            userInfo: ["isOpen": isOpen]
        )
    }
    
    /// Posts a device menu state change notification
    static func postDeviceMenuStateChanged(isOpen: Bool) {
        NotificationCenter.default.post(
            name: NotificationNames.deviceMenuStateChanged,
            object: nil,
            userInfo: ["isOpen": isOpen]
        )
    }
    
    /// Posts a setup complete notification
    static func postSetupComplete() {
        NotificationCenter.default.post(
            name: NotificationNames.setupComplete,
            object: nil
        )
    }
}

