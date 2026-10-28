import Foundation
import CoreAudio
import AudioToolbox

@MainActor
public final class VolumeHUDService: ObservableObject {
    public static let shared = VolumeHUDService()
    
    @Published public private(set) var currentVolume: Float = 0.5
    @Published public private(set) var isMuted: Bool = false
    
    private var defaultOutputDeviceID: AudioDeviceID = 0
    private var volumeListenerBlock: AudioObjectPropertyListenerBlock?
    private var muteListenerBlock: AudioObjectPropertyListenerBlock?
    private var deviceListenerBlock: AudioObjectPropertyListenerBlock?
    
    private var isInitialized = false
    
    public init() {
        setupDeviceAndListeners()
    }
    
    public func setupDeviceAndListeners() {
        defaultOutputDeviceID = fetchDefaultOutputDevice()
        guard defaultOutputDeviceID != 0 else { return }
        
        readCurrentVolume(suppressHUD: true)
        registerListeners()
        isInitialized = true
    }
    
    private func fetchDefaultOutputDevice() -> AudioDeviceID {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : 0
    }
    
    private func readCurrentVolume(suppressHUD: Bool = false) {
        guard defaultOutputDeviceID != 0 else { return }
        
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var vol: Float32 = 0
        var volSize = UInt32(MemoryLayout<Float32>.size)
        let volStatus = AudioObjectGetPropertyData(defaultOutputDeviceID, &volAddress, 0, nil, &volSize, &vol)
        
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muted: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        let muteStatus = AudioObjectGetPropertyData(defaultOutputDeviceID, &muteAddress, 0, nil, &muteSize, &muted)
        
        let newVol = volStatus == noErr ? vol : self.currentVolume
        let newMuted = muteStatus == noErr ? (muted != 0) : false
        
        let didChange = (newVol != self.currentVolume) || (newMuted != self.isMuted)
        
        self.currentVolume = newVol
        self.isMuted = newMuted
        
        if didChange && !suppressHUD && isInitialized {
            if SettingsStore.shared.volumeHUDEnabled {
                IslandStateManager.shared.triggerHUD(.volume(level: newVol, isMuted: newMuted))
            }
        }
    }
    
    private func registerListeners() {
        guard defaultOutputDeviceID != 0 else { return }
        
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let volBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.readCurrentVolume(suppressHUD: false)
            }
        }
        self.volumeListenerBlock = volBlock
        AudioObjectAddPropertyListenerBlock(defaultOutputDeviceID, &volAddress, DispatchQueue.main, volBlock)
        
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let muteBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.readCurrentVolume(suppressHUD: false)
            }
        }
        self.muteListenerBlock = muteBlock
        AudioObjectAddPropertyListenerBlock(defaultOutputDeviceID, &muteAddress, DispatchQueue.main, muteBlock)
        
        // Listen for default device changes (e.g. plugging in headphones or connecting AirPods)
        var devAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let devBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.setupDeviceAndListeners()
            }
        }
        self.deviceListenerBlock = devBlock
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &devAddress, DispatchQueue.main, devBlock)
    }
}
