import Foundation
import AppKit

/// Protocol defining keyboard event monitoring capabilities
protocol KeyboardMonitoring: AnyObject {
    func startMonitoring(volumeUpHandler: @escaping () -> Void,
                        volumeDownHandler: @escaping () -> Void,
                        muteToggleHandler: @escaping () -> Void)
    func stopMonitoring()
}

