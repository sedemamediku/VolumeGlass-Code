import Foundation
import Combine

/// Protocol defining volume monitoring capabilities
protocol VolumeMonitoring: ObservableObject {
    var currentVolume: Float { get }
    var isVolumeChanging: Bool { get }
    var isMuted: Bool { get }
    
    func setSystemVolume(_ volume: Float)
    func toggleMute()
    func getCurrentVolume()
    func checkMuteStatus()
    func startVolumeChangeIndicator()
}

