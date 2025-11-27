import Foundation

/// Centralized notification names used throughout the application
enum NotificationNames {
    static let volumeBarVisibilityChanged = NSNotification.Name("VolumeBarVisibilityChanged")
    static let quickActionsStateChanged = NSNotification.Name("QuickActionsStateChanged")
    static let deviceMenuStateChanged = NSNotification.Name("DeviceMenuStateChanged")
    static let setupComplete = NSNotification.Name("SetupComplete")
}

