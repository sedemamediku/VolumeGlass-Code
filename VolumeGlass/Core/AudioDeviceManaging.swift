import Foundation
import Combine

/// Protocol defining audio device management capabilities
protocol AudioDeviceManaging: ObservableObject {
    var outputDevices: [AudioDevice] { get }
    var inputDevices: [AudioDevice] { get }
    var currentOutputDevice: AudioDevice? { get }
    
    func loadDevices()
    func setOutputDevice(_ device: AudioDevice)
}

