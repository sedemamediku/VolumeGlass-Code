import Foundation
import AppKit

/// Manages the status bar menu and icon
class StatusBarManager {
    private var statusItem: NSStatusItem?
    private let onAbout: () -> Void
    private let onQuit: () -> Void
    
    init(onAbout: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onAbout = onAbout
        self.onQuit = onQuit
    }
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "speaker.wave.3", accessibilityDescription: "VolumeGlass")
        }
        
        let menu = NSMenu()
        let aboutItem = NSMenuItem(title: "About VolumeGlass", action: nil, keyEquivalent: "")
        aboutItem.target = self
        aboutItem.action = #selector(handleAbout)
        menu.addItem(aboutItem)
        // menu.addItem(NSMenuItem(title: "Check for Updates", action: #selector(checkUpdates), keyEquivalent: "")) // Disabled to prevent update errors during development
        menu.addItem(NSMenuItem.separator())
        
        let keyboardHintsItem = NSMenuItem(title: "Keyboard Shortcuts", action: nil, keyEquivalent: "")
        let keyboardSubmenu = NSMenu()
        keyboardSubmenu.addItem(withTitle: "⌘⇧↑  Volume Up", action: nil, keyEquivalent: "")
        keyboardSubmenu.addItem(withTitle: "⌘⇧↓  Volume Down", action: nil, keyEquivalent: "")
        keyboardSubmenu.addItem(withTitle: "⌘⇧M  Toggle Mute", action: nil, keyEquivalent: "")
        keyboardHintsItem.submenu = keyboardSubmenu
        menu.addItem(keyboardHintsItem)
        
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: nil, keyEquivalent: "q")
        quitItem.target = self
        quitItem.action = #selector(handleQuit)
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func handleAbout() {
        onAbout()
    }
    
    @objc private func handleQuit() {
        onQuit()
    }
    
    func updateIconForUpdateAvailable() {
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "speaker.badge.exclamationmark", accessibilityDescription: "Update Available")
        }
    }
    
    func resetIcon() {
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "speaker.wave.3", accessibilityDescription: "VolumeGlass")
        }
    }
}

