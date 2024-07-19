//
//  ViewController.swift
//  D7 Audio
//
//  Created by abdul on 7/18/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var audioEngine: AVAudioEngine!
    var pitchEffect: AVAudioUnitTimePitch!
    var reverbEffect: AVAudioUnitReverb!
    var delayEffect: AVAudioUnitDelay!
    var audioSession: AVAudioSession!
    var playerNode: AVAudioPlayerNode!
    var mixerNode: AVAudioMixerNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        requestMicrophonePermission()
    }

    func requestMicrophonePermission() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("Microphone access granted")
                        self.setupAudioEngine()
                        self.startAudioEngine()
                        self.setupUI()
                    } else {
                        print("Microphone access denied")
                    }
                }
            }
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        pitchEffect = AVAudioUnitTimePitch()
        pitchEffect.pitch = 0 // Default pitch value
        reverbEffect = AVAudioUnitReverb()
        reverbEffect.loadFactoryPreset(.mediumRoom)
        reverbEffect.wetDryMix = 0 // Default reverb value
        delayEffect = AVAudioUnitDelay()
        delayEffect.delayTime = 0 // Default delay time in seconds
        mixerNode = AVAudioMixerNode()
        mixerNode.outputVolume = 0.5 // Default volume

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        audioEngine.attach(playerNode)
        audioEngine.attach(pitchEffect)
        audioEngine.attach(reverbEffect)
        audioEngine.attach(delayEffect)
        audioEngine.attach(mixerNode)
        
        audioEngine.connect(playerNode, to: pitchEffect, format: inputFormat)
        audioEngine.connect(pitchEffect, to: reverbEffect, format: inputFormat)
        audioEngine.connect(reverbEffect, to: delayEffect, format: inputFormat)
        audioEngine.connect(delayEffect, to: mixerNode, format: inputFormat)
        audioEngine.connect(mixerNode, to: audioEngine.outputNode, format: inputFormat)


        inputNode.installTap(onBus: 0, bufferSize: 4410, format: inputFormat) { (buffer, when) in
            self.playerNode.scheduleBuffer(buffer, completionHandler: nil)
        }
    }
    func setAudioPanning(node: AVAudioStereoMixing, pan: Float) {
        node.pan = pan
    }

    // Pan audio fully to the left


    func startAudioEngine() {
        do {
            try audioEngine.start()
            playerNode.play()
            print("Audio engine started")
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    func setupUI() {
        let pitchSlider = UISlider(frame: CGRect(x: 96, y: 460, width: 200, height: 10))
        pitchSlider.minimumValue = -1000 // -2 octaves
        pitchSlider.maximumValue = 1000 // +2 octaves
        pitchSlider.value = 0 // Default pitch shift
        pitchSlider.addTarget(self, action: #selector(pitchSliderChanged(_:)), for: .valueChanged)
        view.addSubview(pitchSlider)

        let reverbSlider = UISlider(frame: CGRect(x: 96, y: 512, width: 200, height: 10))
        reverbSlider.minimumValue = 0 // 0% reverb
        reverbSlider.maximumValue = 100 // 100% reverb
        reverbSlider.value = 0 // Default reverb
        reverbSlider.addTarget(self, action: #selector(reverbSliderChanged(_:)), for: .valueChanged)
        view.addSubview(reverbSlider)

        let delaySlider = UISlider(frame: CGRect(x: 96, y: 572, width: 200, height: 10))
        delaySlider.minimumValue = 0 // 0 seconds
        delaySlider.maximumValue = 0.5 // 2 seconds
        delaySlider.value = 0 // Default delay time
        delaySlider.addTarget(self, action: #selector(delaySliderChanged(_:)), for: .valueChanged)
        view.addSubview(delaySlider)
        
        let volumeSlider = UISlider(frame: CGRect(x: 96, y: 625, width: 200, height: 10))
        volumeSlider.minimumValue = 0 // Mute
        volumeSlider.maximumValue = 1 // Full volume
        volumeSlider.value = 0.5 // Default volume
        volumeSlider.addTarget(self, action: #selector(volumeSliderChanged(_:)), for: .valueChanged)
        view.addSubview(volumeSlider)
    }

    @objc func pitchSliderChanged(_ sender: UISlider) {
        pitchEffect.pitch = sender.value
    }

    @objc func reverbSliderChanged(_ sender: UISlider) {
        reverbEffect.wetDryMix = sender.value
    }

    @objc func delaySliderChanged(_ sender: UISlider) {
        delayEffect.delayTime = TimeInterval(sender.value)
    }
    
    @objc func volumeSliderChanged(_ sender: UISlider) {
        mixerNode.outputVolume = sender.value
    }
}
