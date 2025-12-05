//
//  SpeechRecognitionViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class SpeechRecognitionViewModel: ObservableObject {
    @Published var statusMessage: String = "Speech Recognition permissions management"
}
