# VolumeGlass Directory Structure

This document describes the feature-based organization of the VolumeGlass codebase.

## Directory Organization

```
VolumeGlass/
├── App/                          # Application entry point
│   └── VolumeGlassApp.swift      # Main app struct and AppDelegate
│
├── Core/                         # Core protocols, constants, and utilities
│   ├── VolumeMonitoring.swift   # Volume monitoring protocol
│   ├── AudioDeviceManaging.swift # Audio device management protocol
│   ├── KeyboardMonitoring.swift  # Keyboard monitoring protocol
│   ├── Constants.swift          # Application-wide constants
│   ├── NotificationNames.swift  # Notification name constants
│   └── NotificationHelper.swift # Notification posting utilities
│
├── Audio/                        # Audio functionality
│   ├── VolumeMonitor.swift      # Volume monitoring implementation
│   └── AudioDeviceManager.swift # Audio device management
│
├── UI/                          # User interface components
│   ├── Volume/                  # Volume-related UI
│   │   ├── VolumeControlView.swift    # Main volume control interface
│   │   └── VolumeIndicatorView.swift # Volume bar indicator
│   │
│   ├── Setup/                   # Setup walkthrough UI
│   │   ├── SetupWalkthroughView.swift # Setup flow views
│   │   └── SetupState.swift          # Setup state management
│   │
│   └── Components/              # Reusable UI components
│       └── DeviceSelectionMenu.swift  # Audio device selection menu
│
└── System/                      # System integration
    ├── VolumeOverlayWindow.swift     # Overlay window management
    ├── StatusBarManager.swift        # Menu bar integration
    ├── KeyboardEventMonitor.swift    # Keyboard event handling
    └── UpdateManager.swift           # Update checking
```

## Feature Groups

### App
- **VolumeGlassApp.swift**: Application entry point, window configuration, and AppDelegate coordination

### Core
- **Protocols**: Define contracts for volume monitoring, audio device management, and keyboard monitoring
- **Constants**: Centralized configuration values and notification names
- **Utilities**: Helper functions for common operations (notifications)

### Audio
- **VolumeMonitor**: Monitors system volume changes and manages volume state
- **AudioDeviceManager**: Manages audio device enumeration and selection

### UI/Volume
- **VolumeControlView**: Main volume control interface with quick actions
- **VolumeIndicatorView**: Visual volume bar indicator with drag support

### UI/Setup
- **SetupWalkthroughView**: Multi-step setup walkthrough
- **SetupState**: Manages setup state and preferences

### UI/Components
- **DeviceSelectionMenu**: Reusable audio device selection component

### System
- **VolumeOverlayWindow**: Manages overlay window creation and positioning
- **StatusBarManager**: Handles menu bar icon and menu
- **KeyboardEventMonitor**: Monitors keyboard events for volume shortcuts
- **UpdateManager**: Handles application update checking

## Benefits of This Organization

1. **Clear Separation of Concerns**: Each directory has a single, well-defined responsibility
2. **Easy Navigation**: Developers can quickly find files related to specific features
3. **Scalability**: New features can be added as new directories or subdirectories
4. **Maintainability**: Related code is grouped together, making changes easier
5. **Testability**: Features are isolated, making unit testing more straightforward

## Note for Xcode

When opening this project in Xcode, you may need to:
1. Remove old file references from the project
2. Re-add files from their new locations
3. Ensure all files are included in the correct target

Alternatively, Xcode may automatically detect the new file locations when you open the project.

