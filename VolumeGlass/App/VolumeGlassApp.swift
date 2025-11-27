import SwiftUI
import Carbon

@main
struct VolumeGlassApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var setupState = SetupState()
    @StateObject private var volumeSettings = VolumeControlSettings()
    
    
    init() {
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        if let bundleID = Bundle.main.bundleIdentifier {
            let savedAppStatePath = NSHomeDirectory() + "/Library/Saved Application State/" + bundleID + ".savedState"
            try? FileManager.default.removeItem(atPath: savedAppStatePath)
        }
        
        let userDefaults = UserDefaults.standard
        let dictionary = userDefaults.dictionaryRepresentation()
        for key in dictionary.keys {
            if key.contains("NSWindow Frame") || key.contains("window frame") {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup("Setup") {
            if setupState.isSetupComplete {
                EmptyView()
                    .frame(width: 0, height: 0)
                    .onAppear {
                        appDelegate.volumeSettings = volumeSettings
                        appDelegate.startVolumeMonitoring(with: setupState)
                    }
            } else {
                SetupWalkthroughView(setupState: setupState)
                    .onAppear {
                        appDelegate.setupState = setupState
                    }
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: AppConstants.setupWindowWidth, height: AppConstants.setupWindowHeight)
        .restorationBehavior(.disabled)
        .windowToolbarStyle(.unifiedCompact)
        .onChange(of: setupState.isSetupComplete) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.setupCompleteDelay) {
                    appDelegate.volumeSettings = volumeSettings
                    appDelegate.startVolumeMonitoring(with: setupState)
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var volumeMonitor: VolumeMonitor?
    private var keyboardMonitor: KeyboardEventMonitor?
    private var statusBarManager: StatusBarManager?
    private var updateManager = UpdateManager()
    private var updateCheckTimer: Timer?
    var setupState: SetupState?
    var volumeSettings = VolumeControlSettings()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        UserDefaults.standard.set(false, forKey: "ApplePersistenceIgnoreState")
        
        setupStatusBar()
        // setupAutomaticUpdateChecks() // Disabled to prevent update errors during development
        
        for window in NSApp.windows {
            window.isRestorable = false
        }
    }
    
    private func setupAutomaticUpdateChecks() {
        // Check immediately on launch
        checkForUpdatesInBackground()
        
        // Check every 24 hours
        updateCheckTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.updateCheckInterval, repeats: true) { [weak self] _ in
            self?.checkForUpdatesInBackground()
        }
        
        print("🔄 Automatic update checks enabled (every 24 hours)")
    }
    
    private func checkForUpdatesInBackground() {
        print("🔍 Checking for updates in background...")
        updateManager.checkForUpdates()
        
        // Wait for response then show notification if update available
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.updateCheckDelay) {
            if self.updateManager.updateAvailable {
                self.showUpdateNotification()
            }
        }
    }
    
    private func showUpdateNotification() {
        // Deprecated NSUserNotification removed - update checks are disabled
        // If notifications are needed in the future, use UserNotifications framework
        
        // Also update menu bar icon with badge
        statusBarManager?.updateIconForUpdateAvailable()
        
        print("📢 Update notification (deprecated API removed)")
    }
    
    private func setupStatusBar() {
        statusBarManager = StatusBarManager(
            onAbout: { [weak self] in
                self?.showAbout()
            },
            onQuit: { [weak self] in
                self?.quitApp()
            }
        )
        statusBarManager?.setup()
    }

    @objc private func checkUpdates() {
        print("🔍 Manual update check requested")
        updateManager.checkForUpdates()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.updateCheckDelay) {
            if self.updateManager.updateAvailable {
                let alert = NSAlert()
                alert.messageText = "Update Available! 🎉"
                alert.informativeText = "Version \(self.updateManager.latestVersion) is available.\n\nYou're currently on version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown").\n\nWould you like to download it?"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Download")
                alert.addButton(withTitle: "Later")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    self.updateManager.checkForUpdates()
                    self.statusBarManager?.resetIcon()
                }
            } else {
                let alert = NSAlert()
                alert.messageText = "You're Up to Date! ✅"
                alert.informativeText = "VolumeGlass \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") is the latest version."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    private func handleVolumeUp() {
        guard let volumeMonitor = volumeMonitor else { return }
        let newVolume = min(1.0, volumeMonitor.currentVolume + volumeSettings.volumeStep)
        volumeMonitor.setSystemVolume(Float(newVolume))
    }
    
    private func handleVolumeDown() {
        guard let volumeMonitor = volumeMonitor else { return }
        let newVolume = max(0.0, volumeMonitor.currentVolume - volumeSettings.volumeStep)
        volumeMonitor.setSystemVolume(Float(newVolume))
    }
    
    private func handleMuteToggle() {
        volumeMonitor?.toggleMute()
    }
    
    func startVolumeMonitoring(with setupState: SetupState) {
        if volumeMonitor != nil {
            volumeMonitor = nil
        }
        
        NSApp.setActivationPolicy(.accessory)
        hideAllWindows()
        
        volumeMonitor = VolumeMonitor()
        volumeMonitor?.setupState = setupState
        volumeMonitor?.createVolumeOverlay()
        
        // Setup keyboard monitoring after volume monitor is created
        if let volumeMonitor = volumeMonitor {
            keyboardMonitor = KeyboardEventMonitor(volumeMonitor: volumeMonitor)
            keyboardMonitor?.startMonitoring(
                volumeUpHandler: { [weak self] in
                    self?.handleVolumeUp()
                },
                volumeDownHandler: { [weak self] in
                    self?.handleVolumeDown()
                },
                muteToggleHandler: { [weak self] in
                    self?.handleMuteToggle()
                }
            )
        }
    }
    
    private func hideAllWindows() {
        for window in NSApp.windows {
            window.orderOut(nil)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return volumeMonitor == nil
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        updateCheckTimer?.invalidate()
        keyboardMonitor?.stopMonitoring()
        for window in NSApp.windows {
            window.isRestorable = false
        }
    }
}

