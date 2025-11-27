import SwiftUI

// Background view matching Apple's System Settings style
struct SettingsBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base background with subtle material
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    // Very subtle border that adapts to color scheme
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            colorScheme == .dark 
                                ? Color.white.opacity(0.05) 
                                : Color.black.opacity(0.04),
                            lineWidth: 0.5
                        )
                )
                .shadow(
                    color: colorScheme == .dark 
                        ? Color.black.opacity(0.15) 
                        : Color.black.opacity(0.06),
                    radius: colorScheme == .dark ? 12 : 6,
                    x: 0,
                    y: colorScheme == .dark ? 2 : 1
                )
        }
    }
}

enum MenuPanel: Identifiable {
    case quickVolume
    case settings
    
    var id: String {
        switch self {
        case .quickVolume: return "quickVolume"
        case .settings: return "settings"
        }
    }
}

struct VolumeControlMenu: View {
    @ObservedObject var volumeMonitor: VolumeMonitor
    @ObservedObject var audioDeviceManager: AudioDeviceManager
    @ObservedObject var settings: VolumeControlSettings
    @ObservedObject var setupState: SetupState
    let onDismiss: () -> Void
    let onShowDeviceMenu: () -> Void
    let onShowPositionSelector: () -> Void
    let isRightSide: Bool
    
    @State private var showPresetEditor = false
    @State private var activePanel: MenuPanel? = nil
    @State private var newPresetValue: String = ""
    @State private var editingBarSize: CGFloat = 1.0
    @State private var showBarSizeSaveButton = false
    @Environment(\.colorScheme) var colorScheme
    
    private var volumeIcon: String {
        if volumeMonitor.isMuted { return "speaker.slash.fill" }
        else if volumeMonitor.currentVolume > settings.volumeHighThreshold { return "speaker.wave.3.fill" }
        else if volumeMonitor.currentVolume > settings.volumeMediumThreshold { return "speaker.wave.2.fill" }
        else if volumeMonitor.currentVolume > 0 { return "speaker.wave.1.fill" }
        else { return "speaker.fill" }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Main menu
            mainMenuView
            
            // Side panel
            if let activePanel = activePanel {
                sidePanelView(for: activePanel)
                    .transition(.asymmetric(
                        insertion: .move(edge: isRightSide ? .leading : .trailing)
                            .combined(with: .opacity)
                            .combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: isRightSide ? .leading : .trailing)
                            .combined(with: .opacity)
                            .combined(with: .scale(scale: 0.95))
                    ))
            }
            
            // Close button - appears next to menu/submenu, centered vertically
            // Always on top to ensure it's clickable
            closeButton
                .zIndex(10000)
                .allowsHitTesting(true)
                .contentShape(Circle())
        }
        .animation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping), value: activePanel?.id)
        .onAppear {
            editingBarSize = setupState.barSize
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            // Close submenu first if open, otherwise close main menu
            if let currentPanel = activePanel {
                // Close submenu - use direct state update
                print("🔴 Close button clicked - closing submenu: \(currentPanel.id)")
                activePanel = nil
                if settings.hapticFeedbackEnabled {
                    triggerHapticFeedback()
                }
            } else {
                // Close main menu
                print("🔴 Close button clicked - closing main menu")
                if settings.hapticFeedbackEnabled {
                    triggerHapticFeedback()
                }
                onDismiss()
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.primary.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help(activePanel != nil ? "Close Settings" : "Close Menu")
    }
    
    private var mainMenuView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Minimal Header Section
                HStack(spacing: 8) {
                    Image(systemName: volumeIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .symbolEffect(.pulse, value: volumeMonitor.isVolumeChanging)
                        .animation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping), value: volumeIcon)
                    
                    Text("\(Int(volumeMonitor.currentVolume * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                
                // Quick Volume Presets Section
                VStack(spacing: 8) {
                    Text("Quick Volume")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(settings.customPresets.indices, id: \.self) { index in
                            PresetButton(
                                value: Int(settings.customPresets[index] * 100),
                                action: {
                                    volumeMonitor.setSystemVolume(settings.customPresets[index])
                                    if settings.hapticFeedbackEnabled {
                                        triggerHapticFeedback()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                }
                
                Divider()
                
                // Quick Actions Section
                VStack(spacing: 0) {
                    MenuActionButton(
                        icon: volumeMonitor.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                        label: volumeMonitor.isMuted ? "Unmute" : "Mute",
                        isDestructive: volumeMonitor.isMuted,
                        action: {
                            volumeMonitor.toggleMute()
                            if settings.hapticFeedbackEnabled {
                                triggerHapticFeedback()
                            }
                        }
                    )
                    
                    Divider()
                    
                    MenuActionButton(
                        icon: "hifispeaker.2.fill",
                        label: "Audio Output",
                        action: onShowDeviceMenu
                    )
                }
                
                Divider()
                
                // Settings Section (Button to open side panel)
                MenuActionButton(
                    icon: "gearshape",
                    label: "Settings",
                    hasSubmenu: true,
                    action: {
                        withAnimation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping)) {
                            activePanel = .settings
                        }
                        if settings.hapticFeedbackEnabled {
                            triggerHapticFeedback()
                        }
                    }
                )
                
                Divider()
                
                }
        }
        .frame(width: 200)
        .frame(maxHeight: AppConstants.volumeBarHeight + AppConstants.windowExpansionHeight - 40)
        .background(SettingsBackground())
        .sheet(isPresented: $showPresetEditor) {
            VolumePresetEditor(settings: settings, isPresented: $showPresetEditor)
        }
    }
    
    @ViewBuilder
    private func sidePanelView(for panel: MenuPanel) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                    // Header with back button
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: settings.animationSpeed.springResponse, dampingFraction: settings.animationSpeed.springDamping)) {
                                activePanel = nil
                            }
                            if settings.hapticFeedbackEnabled {
                                triggerHapticFeedback()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isRightSide ? "chevron.right" : "chevron.left")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(panelTitle(for: panel))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Invisible spacer to center title (same width as back button)
                        HStack(spacing: 6) {
                            Image(systemName: isRightSide ? "chevron.right" : "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .opacity(0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                    
                    // Panel content
                    Group {
                        switch panel {
                        case .quickVolume:
                            quickVolumePanel
                        case .settings:
                            settingsPanel
                        }
                    }
                }
        }
        .frame(width: 240)
        .frame(maxHeight: AppConstants.volumeBarHeight + AppConstants.windowExpansionHeight - 40)
        .background(SettingsBackground())
        .zIndex(1)
    }
    
    private func panelTitle(for panel: MenuPanel) -> String {
        switch panel {
        case .quickVolume: return "Quick Volume"
        case .settings: return "Settings"
        }
    }
    
    private var quickVolumePanel: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 0)
            
            Text("Customize your quick volume presets. These buttons appear in the main menu for quick access.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            VStack(spacing: 12) {
                ForEach(settings.customPresets.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text("Preset \(index + 1)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 70, alignment: .leading)
                        
                        Slider(
                            value: Binding(
                                get: { Double(settings.customPresets[index]) },
                                set: { settings.customPresets[index] = Float($0) }
                            ),
                            in: 0...1
                        )
                        .frame(maxWidth: .infinity)
                        
                        Text("\(Int(settings.customPresets[index] * 100))%")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .trailing)
                        
                        Button(action: {
                            settings.customPresets.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
            
            Divider()
            
            Button(action: {
                showPresetEditor = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                    Text("Edit Presets")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            
            Divider()
            
            HStack {
                TextField("New preset (0-100)", text: $newPresetValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                
                Button("Add Preset") {
                    if let value = Float(newPresetValue), value >= 0, value <= 100 {
                        settings.customPresets.append(value / 100.0)
                        newPresetValue = ""
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    private var settingsPanel: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 0)
            // Volume Step Size
            SettingRow(
                icon: "arrow.up.and.down",
                label: "Volume Step",
                value: "\(Int(settings.volumeStep * 100))%"
            ) {
                Slider(
                    value: Binding(
                        get: { Double(settings.volumeStep) },
                        set: { settings.volumeStep = Float($0) }
                    ),
                    in: 0.01...0.10
                )
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Haptic Feedback
            SettingRow(
                icon: "hand.tap",
                label: "Haptic Feedback"
            ) {
                Toggle("", isOn: $settings.hapticFeedbackEnabled)
                    .toggleStyle(.switch)
            }
            
            Divider()
            
            // Visibility Timeout
            SettingRow(
                icon: "timer",
                label: "Visibility Timeout",
                value: "\(Int(settings.visibilityTimeout))s"
            ) {
                Slider(
                    value: $settings.visibilityTimeout,
                    in: 1...5
                )
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Bar Size
            VStack(alignment: .leading, spacing: 8) {
                SettingRow(
                    icon: "arrow.up.left.and.arrow.down.right",
                    label: "Bar Size",
                    value: "\(Int(editingBarSize * 100))%"
                ) {
                    Slider(
                        value: $editingBarSize,
                        in: AppConstants.minBarSize...AppConstants.maxBarSize
                    )
                    .frame(maxWidth: .infinity)
                    .onChange(of: editingBarSize) { oldValue, newValue in
                        if abs(newValue - setupState.barSize) > 0.01 {
                            showBarSizeSaveButton = true
                        } else {
                            showBarSizeSaveButton = false
                        }
                    }
                }
                
                if showBarSizeSaveButton {
                    Button(action: {
                        setupState.barSize = editingBarSize
                        UserDefaults.standard.set(Double(editingBarSize), forKey: "barSize")
                        showBarSizeSaveButton = false
                        // Notify that bar size changed
                        NotificationCenter.default.post(name: NSNotification.Name("BarSizeChanged"), object: nil)
                        if settings.hapticFeedbackEnabled {
                            triggerHapticFeedback()
                        }
                    }) {
                        Text("Set")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            Divider()
            
            // Display Style
            SettingRow(
                icon: "paintbrush",
                label: "Display Style"
            ) {
                Picker("", selection: $settings.displayStyle) {
                    ForEach(VolumeDisplayStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            
            Divider()
            
            // Position
            Button(action: {
                onShowPositionSelector()
                if settings.hapticFeedbackEnabled {
                    triggerHapticFeedback()
                }
            }) {
                HStack {
                    Image(systemName: "location")
                        .font(.system(size: 13, weight: .medium))
                    Text("Change Position")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            
            Divider()
            
            // Animation Speed
            SettingRow(
                icon: "speedometer",
                label: "Animation Speed"
            ) {
                Picker("", selection: $settings.animationSpeed) {
                    ForEach(AnimationSpeed.allCases, id: \.self) { speed in
                        Text(speed.rawValue).tag(speed)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
            
            Divider()
            
            // Volume High Threshold
            SettingRow(
                icon: "waveform",
                label: "High Threshold",
                value: "\(Int(settings.volumeHighThreshold * 100))%"
            ) {
                Slider(
                    value: $settings.volumeHighThreshold,
                    in: 0.5...0.9
                )
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Volume Medium Threshold
            SettingRow(
                icon: "waveform",
                label: "Medium Threshold",
                value: "\(Int(settings.volumeMediumThreshold * 100))%"
            ) {
                Slider(
                    value: $settings.volumeMediumThreshold,
                    in: 0.1...0.5
                )
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Hover Delay
            SettingRow(
                icon: "cursorarrow.click",
                label: "Hover Delay",
                value: String(format: "%.1fs", settings.hoverDelay)
            ) {
                Slider(
                    value: $settings.hoverDelay,
                    in: 0.1...2.0
                )
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Show Drag Handle
            SettingRow(
                icon: "hand.draw",
                label: "Show Drag Handle"
            ) {
                Toggle("", isOn: $settings.showDragHandle)
                    .toggleStyle(.switch)
            }
        }
        .padding(.vertical, 12)
        .padding(.bottom, 16)
    }
    
    private func triggerHapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
}

struct MenuActionButton: View {
    let icon: String
    let label: String
    var isDestructive: Bool = false
    var hasSubmenu: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 20)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                if hasSubmenu {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                (isDestructive ? Color.red.opacity(0.12) : Color.primary.opacity(isHovered ? 0.06 : 0))
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct SettingRow<Content: View>: View {
    let icon: String
    let label: String
    var value: String? = nil
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            content()
        }
        .padding(.horizontal, 12)
    }
}

