import SwiftUI
import AppKit

struct VolumeControlView: View {
    @ObservedObject var volumeMonitor: VolumeMonitor
    @ObservedObject var audioDeviceManager: AudioDeviceManager
    @StateObject private var settings = VolumeControlSettings()
    @State private var showDeviceMenu = false
    @State private var showQuickActions = false
    @State private var showPositionSelector = false
    @Environment(\.colorScheme) var colorScheme
    
    private var isCustomPosition: Bool {
        volumeMonitor.setupState?.selectedPosition == .custom
    }
    
    private var isRightSide: Bool {
        let position = volumeMonitor.setupState?.selectedPosition
        
        // Check if explicitly set to right vertical
        if position == .rightVertical {
            return true
        }
        
        // Check if custom position is on the right side of the screen
        if position == .custom {
            if let customX = volumeMonitor.setupState?.customPositionX {
                // Get the main screen width to determine if position is on right side
                if let screen = NSScreen.main {
                    let screenWidth = screen.visibleFrame.width
                    // Consider right side if custom X is greater than threshold of screen width
                    return customX > screenWidth * AppConstants.rightSideThreshold
                }
            }
        }
        
        return false
    }
    
    private var menuEdge: Edge {
        isRightSide ? .trailing : .leading
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if isRightSide {
                // When on right side, show menus first (on the left)
                if showQuickActions && !showDeviceMenu {
                    VolumeControlMenu(
                        volumeMonitor: volumeMonitor,
                        audioDeviceManager: audioDeviceManager,
                        settings: settings,
                        setupState: volumeMonitor.setupState ?? SetupState(),
                        onDismiss: {
                            withAnimation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping)) {
                                showQuickActions = false
                            }
                            NotificationHelper.postQuickActionsStateChanged(isOpen: false)
                            updateMouseEnabled()
                        },
                        onShowDeviceMenu: {
                            showDeviceMenuWithHaptic()
                        },
                        onShowPositionSelector: {
                            showPositionSelector = true
                        },
                        isRightSide: isRightSide
                    )
                        .transition(.asymmetric(
                        insertion: .move(edge: menuEdge).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: menuEdge).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                        ))
                }
                
                if showDeviceMenu {
                    DeviceSelectionMenu(
                        audioDeviceManager: audioDeviceManager,
                        onDeviceSelected: { device in
                            audioDeviceManager.setOutputDevice(device)
                            hideDeviceMenu()
                        },
                        onDismiss: {
                            hideDeviceMenu()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: menuEdge).combined(with: .opacity),
                        removal: .move(edge: menuEdge).combined(with: .opacity)
                    ))
                }
            }
            
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    if isCustomPosition && settings.showDragHandle {
                        dragHandleIndicator
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    VolumeIndicatorView(
                        volumeMonitor: volumeMonitor,
                        settings: settings,
                        onOpenMenu: {
                            withAnimation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping)) {
                                showQuickActions = true
                            }
                            NotificationHelper.postQuickActionsStateChanged(isOpen: true)
                            if settings.hapticFeedbackEnabled {
                                triggerHapticFeedback()
                            }
                            updateMouseEnabled()
                        }
                    )
                        .frame(width: AppConstants.volumeBarWidth, height: AppConstants.volumeBarHeight)
                        .onLongPressGesture(minimumDuration: AppConstants.longPressDuration) {
                            showDeviceMenuWithHaptic()
                        }
                        .onTapGesture(count: 2) {
                            volumeMonitor.toggleMute()
                        if settings.hapticFeedbackEnabled {
                            triggerHapticFeedback()
                        }
                    }
                }
                Spacer()
            }
            
            if !isRightSide {
                // When on left side, show menus after slider (on the right)
                if showQuickActions && !showDeviceMenu {
                    VolumeControlMenu(
                        volumeMonitor: volumeMonitor,
                        audioDeviceManager: audioDeviceManager,
                        settings: settings,
                        setupState: volumeMonitor.setupState ?? SetupState(),
                        onDismiss: {
                            withAnimation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping)) {
                                showQuickActions = false
                            }
                            NotificationHelper.postQuickActionsStateChanged(isOpen: false)
                            updateMouseEnabled()
                        },
                        onShowDeviceMenu: {
                            showDeviceMenuWithHaptic()
                        },
                        onShowPositionSelector: {
                            showPositionSelector = true
                        },
                        isRightSide: isRightSide
                    )
                        .transition(.asymmetric(
                        insertion: .move(edge: menuEdge).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: menuEdge).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                        ))
                }
                
                if showDeviceMenu {
                    DeviceSelectionMenu(
                        audioDeviceManager: audioDeviceManager,
                        onDeviceSelected: { device in
                            audioDeviceManager.setOutputDevice(device)
                            hideDeviceMenu()
                        },
                        onDismiss: {
                            hideDeviceMenu()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: menuEdge).combined(with: .opacity),
                        removal: .move(edge: menuEdge).combined(with: .opacity)
                    ))
                }
            }
        }
        // Use fixed frame size to prevent constraint update loops
        // Window size: base (60x280) + expansion (520x60) = 580x340
        .frame(
            width: AppConstants.volumeBarWidth + AppConstants.windowExpansionWidth,
            height: AppConstants.volumeBarHeight + AppConstants.windowExpansionHeight,
            alignment: isRightSide ? .trailing : .leading
        )
        .background(
            // Invisible background that allows click-through when menu is closed
            Color.clear
                .allowsHitTesting(showQuickActions || showDeviceMenu)
        )
        .onChange(of: showQuickActions) { oldValue, newValue in updateMouseEnabled() }
        .onChange(of: showDeviceMenu) { oldValue, newValue in updateMouseEnabled() }
        .sheet(isPresented: $showPositionSelector) {
            if let setupState = volumeMonitor.setupState {
                PositionSelectorView(setupState: setupState, isPresented: $showPositionSelector)
            }
        }
    }
    
    private func showDeviceMenuWithHaptic() {
        if settings.hapticFeedbackEnabled {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        }
        audioDeviceManager.loadDevices()
        withAnimation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping)) {
            showQuickActions = false
            showDeviceMenu = true
        }
        NotificationHelper.postQuickActionsStateChanged(isOpen: false)
        NotificationHelper.postDeviceMenuStateChanged(isOpen: true)
        updateMouseEnabled()
    }
    
    private func hideDeviceMenu() {
        withAnimation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping)) {
            showDeviceMenu = false
        }
        NotificationHelper.postDeviceMenuStateChanged(isOpen: false)
        updateMouseEnabled()
    }
    
    private func updateMouseEnabled() {
        let shouldEnable = showQuickActions || showDeviceMenu || volumeMonitor.isVolumeChanging
        NotificationHelper.postVolumeBarVisibilityChanged(isVisible: shouldEnable)
    }
    
    private func triggerHapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
    
    private var dragHandleIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: "hand.draw")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.primary.opacity(0.6))
            Text("Drag")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.primary.opacity(0.5))
        }
        .frame(width: 40)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.7)
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    var isDestructive: Bool = false
    let action: () -> Void
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = false }
            }
            action()
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).frame(width: 20)
                Text(label).font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
            }
            .foregroundColor(isDestructive ? .red.opacity(0.95) : Color.primary.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(isDestructive ? Color.red.opacity(0.2) : Color.primary.opacity(0.12)))
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct PresetButton: View {
    let value: Int
    let action: () -> Void
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = false }
            }
            action()
        }) {
            Text("\(value)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color.primary.opacity(0.95))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.18)))
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

