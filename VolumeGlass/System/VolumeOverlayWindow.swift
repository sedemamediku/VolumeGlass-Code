import SwiftUI
import AppKit

class VolumeOverlayWindow: NSWindow {
    private let volumeMonitor: VolumeMonitor
    private let audioDeviceManager: AudioDeviceManager
    private var windowOrderTimer: Timer?
    private let targetScreen: NSScreen
    private var isDragging = false
    private var dragStartLocation: NSPoint = .zero
    private var dragStartWindowOrigin: NSPoint = .zero
    // Store the initial frame size to prevent resizing
    private let fixedFrameSize: NSSize
    // Track menu state for click-through (internal so hosting view can access)
    var isQuickActionsOpen = false
    var isDeviceMenuOpen = false
    // Track bar visibility to enable click-through when hidden (internal so hosting view can access)
    var isBarVisible = false
    
    init(volumeMonitor: VolumeMonitor, screen: NSScreen) {
        self.volumeMonitor = volumeMonitor
        self.targetScreen = screen
        self.audioDeviceManager = AudioDeviceManager()
        
        // CRITICAL: Use the specific screen's frame
        let screenFrame = screen.visibleFrame
        let setupState = volumeMonitor.setupState
        let selectedPosition = setupState?.selectedPosition ?? .leftMiddleVertical
        let barSize = setupState?.barSize ?? 1.0
        
        // Get the base position for the bar on THIS screen
        var baseWindowFrame = selectedPosition.getScreenPosition(screenFrame: screenFrame, barSize: barSize)
        
        // If custom position, use saved coordinates
        if selectedPosition == .custom {
            if let customX = setupState?.customPositionX, let customY = setupState?.customPositionY {
                // customX and customY are relative to screen for the base window position
                baseWindowFrame.origin.x = screenFrame.origin.x + customX
                baseWindowFrame.origin.y = screenFrame.origin.y + customY
            }
        }
        
        // Expand window to accommodate menus
        // Add padding on left/top and expand width/height for menu space
        let expandedWindowFrame = NSRect(
            x: baseWindowFrame.minX - AppConstants.windowPadding,
            y: baseWindowFrame.minY - AppConstants.windowPadding,
            width: baseWindowFrame.width + AppConstants.windowExpansionWidth,
            height: baseWindowFrame.height + AppConstants.windowExpansionHeight
        )
        
        // Store the fixed frame size to prevent resizing (must be before super.init)
        self.fixedFrameSize = expandedWindowFrame.size
        
        super.init(
            contentRect: expandedWindowFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindowProperties()
        setupContentView()
        audioDeviceManager.loadDevices()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(barVisibilityChanged(_:)),
            name: NotificationNames.volumeBarVisibilityChanged,
            object: nil
        )
        
        // Listen to menu state changes to enable/disable click-through
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuStateChanged(_:)),
            name: NotificationNames.quickActionsStateChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuStateChanged(_:)),
            name: NotificationNames.deviceMenuStateChanged,
            object: nil
        )
        
        print("📺 Window created on screen: \(screen.localizedName)")
        print("   Screen frame: \(screenFrame)")
        print("   Window frame: \(expandedWindowFrame)")
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    // Prevent automatic window resizing from SwiftUI content changes
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        // Always maintain the fixed size to prevent constraint update loops
        // Only allow position changes (origin), not size changes
        var fixedFrame = frameRect
        fixedFrame.size = fixedFrameSize
        super.setFrame(fixedFrame, display: flag)
    }
    
    override func setContentSize(_ size: NSSize) {
        // Prevent content size changes from triggering window resizes
        // The window size is fixed at initialization
        super.setContentSize(fixedFrameSize)
    }
    
    private func setupWindowProperties() {
        self.isRestorable = false
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        
        // Initially ignore mouse events - will be updated based on bar visibility
        self.ignoresMouseEvents = true
        
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.hidesOnDeactivate = false
        
        // NSWindow automatically binds to the correct screen based on frame position
        // No manual screen binding needed - the window's screen property handles this
        self.orderFrontRegardless()
    }
    
    private func setupContentView() {
        let hostingView = ClickThroughHostingView(
            rootView: VolumeControlView(
                volumeMonitor: volumeMonitor,
                audioDeviceManager: audioDeviceManager
            )
            .background(.clear),
            volumeMonitor: volumeMonitor,
            window: self
        )
        
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        // CRITICAL: Disable automatic resizing to prevent constraint update loops
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set explicit size constraints matching the window's content size
        // This prevents the hosting view from triggering window resizes
        let contentSize = self.contentRect(forFrameRect: self.frame).size
        
        self.contentView = hostingView
        
        // Add explicit constraints to pin the hosting view to the content view with fixed size
        // Using only size constraints and position constraints (not both size and edge constraints)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: self.contentView!.leadingAnchor),
            hostingView.topAnchor.constraint(equalTo: self.contentView!.topAnchor),
            hostingView.widthAnchor.constraint(equalToConstant: contentSize.width),
            hostingView.heightAnchor.constraint(equalToConstant: contentSize.height)
        ])
    }
    
    @objc private func barVisibilityChanged(_ notification: Notification) {
        // Update bar visibility state
        if let userInfo = notification.userInfo,
           let isVisible = userInfo["isVisible"] as? Bool {
            isBarVisible = isVisible
            updateMouseEventHandling()
        }
    }
    
    @objc private func menuStateChanged(_ notification: Notification) {
        // Update menu state from notification
        if let userInfo = notification.userInfo,
           let isOpen = userInfo["isOpen"] as? Bool {
            if notification.name == NotificationNames.quickActionsStateChanged {
                isQuickActionsOpen = isOpen
            } else if notification.name == NotificationNames.deviceMenuStateChanged {
                isDeviceMenuOpen = isOpen
            }
            updateMouseEventHandling()
        }
    }
    
    /// Updates window's mouse event handling based on bar visibility and menu state
    private func updateMouseEventHandling() {
        // Enable mouse events only when bar is visible OR any menu is open
        // This allows click-through when everything is hidden
        let anyMenuOpen = isQuickActionsOpen || isDeviceMenuOpen
        self.ignoresMouseEvents = !isBarVisible && !anyMenuOpen
    }
    
    override func mouseDown(with event: NSEvent) {
        let isCustom = volumeMonitor.setupState?.selectedPosition == .custom
        if isCustom {
            // Check if click is within the drag handle area
            let locationInWindow = event.locationInWindow
            if isPointInDragHandleArea(locationInWindow) {
                isDragging = true
                // Store the initial mouse location in screen coordinates and the window's origin
                dragStartLocation = NSEvent.mouseLocation
                dragStartWindowOrigin = self.frame.origin
            } else {
                // Click is outside drag handle, don't start dragging
                super.mouseDown(with: event)
            }
        } else {
            super.mouseDown(with: event)
        }
    }
    
    /// Checks if a point (in window coordinates) is within the drag handle area
    private func isPointInDragHandleArea(_ point: NSPoint) -> Bool {
        // Drag handle is positioned at windowPadding from left edge
        // Width: 40px (from dragHandleIndicator in VolumeControlView)
        // Height: approximately 60-80px (with padding)
        let dragHandleX: CGFloat = AppConstants.windowPadding
        let dragHandleWidth: CGFloat = 40
        let dragHandleHeight: CGFloat = 80 // Approximate height including padding
        let windowHeight = self.frame.height
        let dragHandleY = (windowHeight - dragHandleHeight) / 2 // Center vertically
        
        let dragHandleRect = NSRect(
            x: dragHandleX,
            y: dragHandleY,
            width: dragHandleWidth,
            height: dragHandleHeight
        )
        
        return dragHandleRect.contains(point)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let isCustom = volumeMonitor.setupState?.selectedPosition == .custom
        if isCustom && isDragging {
            let currentLocation = NSEvent.mouseLocation
            // Calculate total delta from the initial mouse down location
            let totalDeltaX = currentLocation.x - dragStartLocation.x
            let totalDeltaY = currentLocation.y - dragStartLocation.y
            
            // Apply the total delta to the original window position
            var newFrame = self.frame
            newFrame.origin.x = dragStartWindowOrigin.x + totalDeltaX
            newFrame.origin.y = dragStartWindowOrigin.y + totalDeltaY
            
            // Use NSWindow's built-in method to constrain frame to screen bounds
            // This automatically handles screen edge constraints without manual calculations
            let constrainedFrame = self.constrainFrameRect(newFrame, to: targetScreen)
            
            self.setFrame(constrainedFrame, display: true)
        } else {
            super.mouseDragged(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        let isCustom = volumeMonitor.setupState?.selectedPosition == .custom
        if isCustom && isDragging {
            isDragging = false
            
            // Save the base window position relative to screen
            // Calculate base position by removing the expansion padding
            let screenFrame = targetScreen.visibleFrame
            let baseOrigin = NSPoint(
                x: self.frame.origin.x + AppConstants.windowPadding,
                y: self.frame.origin.y + AppConstants.windowPadding
            )
            let relativeX = baseOrigin.x - screenFrame.origin.x
            let relativeY = baseOrigin.y - screenFrame.origin.y
            
            volumeMonitor.setupState?.saveCustomPosition(x: relativeX, y: relativeY)
            print("💾 Saved custom position: (\(relativeX), \(relativeY))")
        } else {
            super.mouseUp(with: event)
        }
    }
    
    func showVolumeIndicator() {
        self.alphaValue = 1.0
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        
        windowOrderTimer?.invalidate()
        windowOrderTimer = Timer(timeInterval: AppConstants.windowOrderCheckInterval, repeats: true) { [weak self] timer in
            guard let self = self, self.isVisible else {
                timer.invalidate()
                return
            }
            // Only call orderFrontRegardless if window is actually visible and not minimized
            if self.alphaValue > 0 && !self.isMiniaturized {
                self.orderFrontRegardless()
            }
        }
        // Use common run loop mode to avoid blocking main thread during scrolling/tracking
        if let timer = windowOrderTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    deinit {
        windowOrderTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// Custom hosting view for volume control
class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    private weak var volumeMonitor: VolumeMonitor?
    private weak var overlayWindow: VolumeOverlayWindow?
    
    init(rootView: Content, volumeMonitor: VolumeMonitor, window: VolumeOverlayWindow) {
        self.volumeMonitor = volumeMonitor
        self.overlayWindow = window
        super.init(rootView: rootView)
    }
    
    required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // First, let SwiftUI handle normal hit testing
        let hitView = super.hitTest(point)
        
        // If SwiftUI found a child view (slider, menu, etc.), always return it
        if hitView != nil && hitView != self {
            return hitView
        }
        
        // If no menu is open and bar is not visible, allow click-through for entire window
        guard let overlayWindow = overlayWindow else {
            return hitView
        }
        
        let anyMenuOpen = overlayWindow.isQuickActionsOpen || overlayWindow.isDeviceMenuOpen
        let barVisible = overlayWindow.isBarVisible
        
        // If bar is hidden and no menus are open, allow click-through for entire window
        if !barVisible && !anyMenuOpen {
            return nil
        }
        
        // If bar is visible but no menu is open, allow click-through for menu area only
        if barVisible && !anyMenuOpen {
            if isPointInMenuArea(point) {
                return nil
            }
        }
        
        // Otherwise, return SwiftUI's result
        return hitView
    }
    
    /// Checks if a point (in view coordinates) is in the menu area
    private func isPointInMenuArea(_ point: NSPoint) -> Bool {
        let viewWidth = self.bounds.width
        let menuAreaWidth = AppConstants.windowExpansionWidth
        let sliderAreaWidth = AppConstants.volumeBarWidth
        
        // Determine which side the menu is on based on setup state
        let isRightSide: Bool
        if let setupState = volumeMonitor?.setupState {
            let position = setupState.selectedPosition
            if position == .rightVertical {
                isRightSide = true
            } else if position == .custom {
                // For custom, check if it's on the right side
                if let customX = setupState.customPositionX,
                   let screen = NSScreen.main {
                    let screenWidth = screen.visibleFrame.width
                    isRightSide = customX > screenWidth * AppConstants.rightSideThreshold
                } else {
                    isRightSide = false
                }
            } else {
                isRightSide = false
            }
        } else {
            isRightSide = false
        }
        
        // Menu area: if right side, menu is on left (0 to menuAreaWidth)
        //            if left side, menu is on right (sliderAreaWidth + padding to viewWidth)
        if isRightSide {
            // Menu is on the left side
            return point.x >= 0 && point.x <= menuAreaWidth
        } else {
            // Menu is on the right side
            // Slider area is at the left with padding, menu area is after that
            let sliderAreaEnd = AppConstants.windowPadding + sliderAreaWidth
            return point.x >= sliderAreaEnd && point.x <= viewWidth
        }
    }
    
}

