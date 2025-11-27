import SwiftUI
import AppKit

struct VolumeIndicatorView: View {
    @ObservedObject var volumeMonitor: VolumeMonitor
    @ObservedObject var settings: VolumeControlSettings
    var onOpenMenu: (() -> Void)? = nil
    var isRightSide: Bool = false  // Track if bar is on right side of screen
    
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var showVolumeBar = false
    @State private var hoverTimer: Timer?
    @State private var pulseAnimation = false
    @State private var isDeviceMenuOpen = false
    @State private var isQuickActionsOpen = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var hasOpenedMenuFromDrag = false
    @Environment(\.colorScheme) var colorScheme
    
    private var setupState: SetupState? { volumeMonitor.setupState }
    private var barSize: CGFloat { setupState?.barSize ?? 1.0 }
    private var isVertical: Bool { setupState?.selectedPosition.isVertical ?? true }

    private var barHeight: CGFloat { AppConstants.baseBarHeight * barSize }
    private var normalWidth: CGFloat { AppConstants.baseBarWidth * barSize }
    private var expandedWidth: CGFloat { AppConstants.expandedBarWidth * barSize }
    private var cornerRadius: CGFloat { AppConstants.cornerRadiusMultiplier * barSize }
    
    private var hoverZoneWidth: CGFloat { isVertical ? 100 : barHeight + AppConstants.hoverZoneExtension }
    private var hoverZoneHeight: CGFloat { isVertical ? barHeight + AppConstants.hoverZoneExtension : 100 }
    
    var effectiveWidth: CGFloat {
        (isHovering || isDragging || volumeMonitor.isVolumeChanging || isDeviceMenuOpen || isQuickActionsOpen) ? expandedWidth : normalWidth
    }
    
    var body: some View {
        ZStack {
            // Right-click detector as background layer
            RightClickDetector(onRightClick: {
                onOpenMenu?()
            })
            .frame(width: hoverZoneWidth, height: hoverZoneHeight)
            
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: hoverZoneWidth, height: hoverZoneHeight)
                .onHover { hovering in
                    handleHover(hovering)
                }
            
            Group {
                if isVertical {
                    verticalVolumeBar
                } else {
                    horizontalVolumeBar
                }
            }
            .opacity(showVolumeBar ? 1.0 : 0.0)
        }
        .frame(width: hoverZoneWidth, height: hoverZoneHeight)
        .animation(.easeInOut(duration: 0.25), value: showVolumeBar)
        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.4), value: effectiveWidth)
        .onReceive(volumeMonitor.$isVolumeChanging) { isChanging in
            handleVolumeChanging(isChanging)
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationNames.deviceMenuStateChanged)) { notification in
            if let isOpen = notification.userInfo?["isOpen"] as? Bool, isDeviceMenuOpen != isOpen {
                isDeviceMenuOpen = isOpen
                if isOpen {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showVolumeBar = true
                    }
                    NotificationHelper.postVolumeBarVisibilityChanged(isVisible: true)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationNames.quickActionsStateChanged)) { notification in
            if let isOpen = notification.userInfo?["isOpen"] as? Bool, isQuickActionsOpen != isOpen {
                isQuickActionsOpen = isOpen
                if isOpen {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showVolumeBar = true
                    }
                    NotificationHelper.postVolumeBarVisibilityChanged(isVisible: true)
                }
            }
        }
        .accessibilityLabel("Volume: \(Int(volumeMonitor.currentVolume * 100))%")
        .accessibilityValue("\(Int(volumeMonitor.currentVolume * 100)) percent")
    }
    
    private var verticalVolumeBar: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack(alignment: .bottom) {
                backgroundTrack.frame(width: effectiveWidth, height: barHeight)
                volumeFill.frame(width: effectiveWidth, height: calculateFillHeight())
                if volumeMonitor.isMuted { muteOverlay }
            }
            .frame(width: effectiveWidth, height: barHeight)
            .scaleEffect(isDragging ? 1.02 : 1.0)
            .gesture(verticalDragGesture)
            Spacer()
        }
    }
    
    private var horizontalVolumeBar: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                backgroundTrack.frame(width: barHeight, height: effectiveWidth)
                volumeFill.frame(width: calculateFillWidth(), height: effectiveWidth)
                if volumeMonitor.isMuted { muteOverlay }
            }
            .frame(width: barHeight, height: effectiveWidth)
            .scaleEffect(isDragging ? 1.02 : 1.0)
            .gesture(horizontalDragGesture)
            Spacer()
        }
    }
    
    private var backgroundTrack: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.clear)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(settings.displayStyle == .liquidGlass ? .ultraThinMaterial : .ultraThinMaterial)
                    .opacity(settings.displayStyle == .liquidGlass ? (colorScheme == .dark ? 0.2 : 0.15) : (colorScheme == .dark ? 0.3 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: settings.displayStyle == .liquidGlass ? [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ] : [
                                Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.25),
                                Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: settings.displayStyle == .liquidGlass ? 0.3 : 0.5
                    )
            )
            .shadow(color: .black.opacity(settings.displayStyle == .liquidGlass ? 0.05 : (colorScheme == .dark ? 0.1 : 0.2)), radius: settings.displayStyle == .liquidGlass ? 2 : 3, x: 0, y: settings.displayStyle == .liquidGlass ? 1 : 2)
    }
    
    private var volumeFill: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: volumeMonitor.isMuted ? [
                        Color.gray.opacity(0.6),
                        Color.gray.opacity(0.4)
                    ] : (settings.displayStyle == .liquidGlass ? liquidGlassGradientColors : adaptiveGradientColors),
                    startPoint: isVertical ? .top : .leading,
                    endPoint: isVertical ? .bottom : .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: settings.displayStyle == .liquidGlass ? [
                                Color.white.opacity(0.2),
                                Color.clear
                            ] : [
                                (colorScheme == .dark ? Color.white : Color.black).opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: settings.displayStyle == .liquidGlass ? Color.white.opacity(0.1) : (colorScheme == .dark ? Color.white : Color.black).opacity(0.2), radius: settings.displayStyle == .liquidGlass ? 1 : 2, x: 0, y: isVertical ? (settings.displayStyle == .liquidGlass ? 0 : -1) : 0)
            .shadow(color: .black.opacity(settings.displayStyle == .liquidGlass ? 0.08 : 0.15), radius: settings.displayStyle == .liquidGlass ? 2 : 3, x: 0, y: isVertical ? (settings.displayStyle == .liquidGlass ? 1 : 2) : 0)
    }
    
    private var adaptiveGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color.white.opacity(0.95),
                Color.white.opacity(0.85),
                Color.white.opacity(0.75)
            ]
        } else {
            return [
                Color(red: 0.2, green: 0.25, blue: 0.3).opacity(0.95),
                Color(red: 0.15, green: 0.2, blue: 0.25).opacity(0.9),
                Color(red: 0.1, green: 0.15, blue: 0.2).opacity(0.85)
            ]
        }
    }
    
    private var liquidGlassGradientColors: [Color] {
        // White bar like macOS built-in audio, with subtle gradient
        return [
            Color.white.opacity(0.95),
            Color.white.opacity(0.92),
            Color.white.opacity(0.9)
        ]
    }
    
    private var muteOverlay: some View {
        Image(systemName: "speaker.slash.fill")
            .font(.system(size: 12 * barSize, weight: .semibold))
            .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.2, blue: 0.2))
            .opacity(0.9)
            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulseAnimation)
            .onAppear { pulseAnimation = true }
    }
    
    private func calculateFillHeight() -> CGFloat {
        if volumeMonitor.isMuted { return cornerRadius * 2 }
        return max(cornerRadius * 2, barHeight * CGFloat(volumeMonitor.currentVolume))
    }
    
    private func calculateFillWidth() -> CGFloat {
        if volumeMonitor.isMuted { return cornerRadius * 2 }
        return max(cornerRadius * 2, barHeight * CGFloat(volumeMonitor.currentVolume))
    }
    
    private func handleVolumeChanging(_ isChanging: Bool) {
        if isChanging {
            // Only show if not already showing to avoid redundant animations
            if !showVolumeBar {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showVolumeBar = true
                }
                NotificationHelper.postVolumeBarVisibilityChanged(isVisible: true)
            }
        } else {
            if !isDeviceMenuOpen && !isQuickActionsOpen {
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.visibilityTimeout) {
                    if !self.isHovering && !self.isDragging && !self.isDeviceMenuOpen && !self.isQuickActionsOpen {
                        withAnimation(.easeOut(duration: 0.4)) {
                            self.showVolumeBar = false
                        }
                        NotificationHelper.postVolumeBarVisibilityChanged(isVisible: false)
                    }
                }
            }
        }
    }
    
    private func handleHover(_ hovering: Bool) {
        hoverTimer?.invalidate()
        
        // Only update if state actually changed
        guard hovering != isHovering else { return }
        
        if hovering {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = true
                if !showVolumeBar {
                    showVolumeBar = true
                }
            }
            NotificationHelper.postVolumeBarVisibilityChanged(isVisible: true)
        } else {
            hoverTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.hoverDelay, repeats: false) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.isHovering = false
                }
                
                if !self.volumeMonitor.isVolumeChanging && !self.isDragging && !self.isDeviceMenuOpen && !self.isQuickActionsOpen {
                    DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.visibilityTimeoutAfterHover) {
                        if !self.isHovering && !self.isDragging && !self.volumeMonitor.isVolumeChanging && !self.isDeviceMenuOpen && !self.isQuickActionsOpen {
                            withAnimation(.easeOut(duration: 0.4)) {
                                self.showVolumeBar = false
                            }
                            NotificationHelper.postVolumeBarVisibilityChanged(isVisible: false)
                        }
                    }
                }
            }
        }
    }
    
    private func triggerHapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
    
    private var verticalDragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if !isDragging {
                    // Store initial drag location
                    dragStartLocation = value.startLocation
                    hasOpenedMenuFromDrag = false
                }
                
                // Check for directional drag to open menu
                let horizontalTranslation = value.translation.width
                let dragThreshold: CGFloat = 20 // Minimum drag distance to trigger menu
                
                if !hasOpenedMenuFromDrag && abs(horizontalTranslation) > dragThreshold {
                    // Left side: drag right (positive X) opens menu
                    // Right side: drag left (negative X) opens menu
                    let shouldOpenMenu = isRightSide 
                        ? horizontalTranslation < -dragThreshold  // Right side: drag left
                        : horizontalTranslation > dragThreshold   // Left side: drag right
                    
                    if shouldOpenMenu {
                        onOpenMenu?()
                        hasOpenedMenuFromDrag = true
                    }
                }
                
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.9)) {
                    isDragging = true
                    showVolumeBar = true
                }
                let dragY = value.location.y
                let newVolume = max(0, min(1, 1 - (dragY / barHeight)))
                let volumePercent = Int(newVolume * 100)
                if volumePercent % 50 == 0 { triggerHapticFeedback() }
                volumeMonitor.setSystemVolume(Float(newVolume))
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isDragging = false
                }
                hasOpenedMenuFromDrag = false
                if !isHovering && !isDeviceMenuOpen && !isQuickActionsOpen {
                    DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.dragEndTimeout) {
                        if !self.isHovering && !self.isDragging && !self.isDeviceMenuOpen && !self.isQuickActionsOpen {
                            withAnimation(.easeOut(duration: 0.4)) {
                                self.showVolumeBar = false
                            }
                        }
                    }
                }
            }
    }
    
    private var horizontalDragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if !isDragging {
                    // Store initial drag location
                    dragStartLocation = value.startLocation
                    hasOpenedMenuFromDrag = false
                }
                
                // Check for directional drag to open menu
                let horizontalTranslation = value.translation.width
                let dragThreshold: CGFloat = 20 // Minimum drag distance to trigger menu
                
                if !hasOpenedMenuFromDrag && abs(horizontalTranslation) > dragThreshold {
                    // Left side: drag right (positive X) opens menu
                    // Right side: drag left (negative X) opens menu
                    let shouldOpenMenu = isRightSide 
                        ? horizontalTranslation < -dragThreshold  // Right side: drag left
                        : horizontalTranslation > dragThreshold   // Left side: drag right
                    
                    if shouldOpenMenu {
                        onOpenMenu?()
                        hasOpenedMenuFromDrag = true
                    }
                }
                
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.9)) {
                    isDragging = true
                    showVolumeBar = true
                }
                let dragX = value.location.x
                let newVolume = max(0, min(1, dragX / barHeight))
                let volumePercent = Int(newVolume * 100)
                if volumePercent % 50 == 0 { triggerHapticFeedback() }
                volumeMonitor.setSystemVolume(Float(newVolume))
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isDragging = false
                }
                hasOpenedMenuFromDrag = false
                if !isHovering && !isDeviceMenuOpen && !isQuickActionsOpen {
                    DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.dragEndTimeout) {
                        if !self.isHovering && !self.isDragging && !self.isDeviceMenuOpen && !self.isQuickActionsOpen {
                            withAnimation(.easeOut(duration: 0.4)) {
                                self.showVolumeBar = false
                            }
                        }
                    }
                }
            }
    }
}

// Helper view to detect right-click events using AppKit
struct RightClickDetector: NSViewRepresentable {
    let onRightClick: () -> Void
    
    func makeNSView(context: Context) -> RightClickView {
        let view = RightClickView()
        view.onRightClick = onRightClick
        return view
    }
    
    func updateNSView(_ nsView: RightClickView, context: Context) {
        nsView.onRightClick = onRightClick
    }
}

class RightClickView: NSView {
    var onRightClick: (() -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Make view transparent but still receive mouse events
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        // Check if this is a right-click (button 2) or two-finger click
        if event.type == .rightMouseDown || event.buttonNumber == 1 {
            onRightClick?()
        } else {
            super.mouseDown(with: event)
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
        super.rightMouseDown(with: event)
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always return self to ensure we receive mouse events
        return self.bounds.contains(point) ? self : nil
    }
}

