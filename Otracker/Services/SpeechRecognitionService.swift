//
//  SpeechRecognitionService.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//


import Foundation
import Speech
import AVFoundation

class SpeechRecognitionService: ObservableObject {
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var error: String?

    func startRecording() {
        guard !isRecording else { return }
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if authStatus == .authorized && granted {
                        self.isRecording = true
                        self.error = nil
                        self.startRecognition()
                    } else {
                        self.error = "Izin untuk mikrofon atau pengenalan suara ditolak."
                    }
                }
            }
        }
    }
    
    private func startRecognition() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Audio session setup error: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.stopRecording()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            self.error = "Audio engine start error: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
}
