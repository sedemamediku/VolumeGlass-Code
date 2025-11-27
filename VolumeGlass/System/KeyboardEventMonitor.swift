import Foundation
import AppKit
import Carbon

/// Handles keyboard event monitoring for volume control shortcuts
class KeyboardEventMonitor: KeyboardMonitoring {
    private var eventMonitor: Any?
    private weak var volumeMonitor: (any VolumeMonitoring)?
    
    init(volumeMonitor: any VolumeMonitoring) {
        self.volumeMonitor = volumeMonitor
    }
    
    func startMonitoring(volumeUpHandler: @escaping () -> Void,
                        volumeDownHandler: @escaping () -> Void,
                        muteToggleHandler: @escaping () -> Void) {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .systemDefined, .flagsChanged]) { [weak self] event in
            guard self != nil else { return }
            
            // Handle system-defined events (hardware volume keys)
            if event.type == .systemDefined && event.subtype.rawValue == 8 {
                let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
                let keyFlags = (event.data1 & 0x0000FFFF)
                let keyPressed = ((keyFlags & 0xFF00) >> 8) == 0xA
                
                if keyPressed {
                    switch Int32(keyCode) {
                    case NX_KEYTYPE_SOUND_UP: volumeUpHandler()
                    case NX_KEYTYPE_SOUND_DOWN: volumeDownHandler()
                    case NX_KEYTYPE_MUTE: muteToggleHandler()
                    default: break
                    }
                }
            }
            
            // Handle keyboard shortcuts (Command+Shift combinations)
            if event.type == .keyDown {
                let flags = event.modifierFlags
                let keyCode = event.keyCode
                
                if flags.contains([.command, .shift]) && keyCode == 126 {
                    volumeUpHandler()
                } else if flags.contains([.command, .shift]) && keyCode == 125 {
                    volumeDownHandler()
                } else if flags.contains([.command, .shift]) && event.characters?.lowercased() == "m" {
                    muteToggleHandler()
                }
            }
        }
    }
    
    func stopMonitoring() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

