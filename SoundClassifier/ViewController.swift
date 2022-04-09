//
//  ViewController.swift
//  SoundClassifier
//
//  Created by Ahmed Abdelkarim on 09/04/2022.
//

import UIKit

class ViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var backgroundProgressView: UIProgressView!
    @IBOutlet weak var backgroundPercentageLabel: UILabel!
    
    @IBOutlet weak var singleClapProgressView: UIProgressView!
    @IBOutlet weak var singleClapPercentageLabel: UILabel!
    
    @IBOutlet weak var doubleClapProgressView: UIProgressView!
    @IBOutlet weak var doubleClapPercentageLabel: UILabel!
    
    @IBOutlet weak var whistleProgressView: UIProgressView!
    @IBOutlet weak var whistlePercentageLabel: UILabel!
    
    @IBOutlet weak var lastDetectionLabel: UILabel!
    @IBOutlet weak var lastDetectionPercentageLabel: UILabel!
    
    // MARK: - Properties
    private var audioInputManager: AudioInputManager!
    private var soundClassifier: SoundClassifier!
    private var bufferSize: Int = 0
    private var probabilities: [Float32] = []
    private var sounds = ["Double Clap", "Single Clap", "Whistle"]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        soundClassifier = SoundClassifier(modelFileName: "soundclassifier_with_metadata", delegate: self)
        
        startAudioRecognition()
    }
    
    // MARK: - Methods
    /// Initializes the AudioInputManager and starts recognizing on the output buffers.
    private func startAudioRecognition() {
        audioInputManager = AudioInputManager(sampleRate: soundClassifier.sampleRate)
        audioInputManager.delegate = self
        
        bufferSize = audioInputManager.bufferSize
        
        audioInputManager.checkPermissionsAndStartTappingMicrophone()
    }
    
    private func runModel(inputBuffer: [Int16]) {
        soundClassifier.start(inputBuffer: inputBuffer)
    }
    
    func updateProbabilities(_ probabilities: [Float32]) {
        guard probabilities.count == 4 else {
            return
        }
        
        for probability in probabilities {
            if probability.isNaN {
                return
            }
        }
        
        // show all detections
        backgroundProgressView.progress = probabilities[0]
        backgroundPercentageLabel.text = "\(Int(probabilities[0] * 100))%"
        
        singleClapProgressView.progress = probabilities[2]
        singleClapPercentageLabel.text = "\(Int(probabilities[2] * 100))%"
        
        doubleClapProgressView.progress = probabilities[1]
        doubleClapPercentageLabel.text = "\(Int(probabilities[1] * 100))%"
        
        whistleProgressView.progress = probabilities[3]
        whistlePercentageLabel.text = "\(Int(probabilities[3] * 100))%"
        
        // show last detected sound
        var maxProbability = Float32(0)
        var maxProbabilityIndex = 1
        
        for i in 1..<probabilities.count {
            if probabilities[i] > maxProbability {
                maxProbability = probabilities[i]
                maxProbabilityIndex = i - 1
            }
        }
        
        if maxProbability > 0.95 {
            lastDetectionLabel.text = sounds[maxProbabilityIndex]
            lastDetectionPercentageLabel.text = "\(Int(maxProbability * 100))%"
        }
    }
}

extension ViewController: AudioInputManagerDelegate {
    func audioInputManagerDidFailToAchievePermission(_ audioInputManager: AudioInputManager) {
        let alertController = UIAlertController(title: "Microphone Permissions Denied", message: "Microphone permissions have been denied for this app. You can change this by going to Settings", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func audioInputManager(_ audioInputManager: AudioInputManager, didCaptureChannelData channelData: [Int16]) {
        let sampleRate = soundClassifier.sampleRate
        self.runModel(inputBuffer: Array(channelData[0..<sampleRate]))
        self.runModel(inputBuffer: Array(channelData[sampleRate..<bufferSize]))
    }
}

extension ViewController: SoundClassifierDelegate {
    func soundClassifier(_ soundClassifier: SoundClassifier, didInterpretProbabilities probabilities: [Float32]) {
        self.probabilities = probabilities
        
        //print(probabilities)
        DispatchQueue.main.async {
            self.updateProbabilities(probabilities)
        }
    }
}
