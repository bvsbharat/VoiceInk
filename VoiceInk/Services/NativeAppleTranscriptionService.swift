import Foundation
import AVFoundation
import os

/// Transcription service that leverages the new SpeechAnalyzer / SpeechTranscriber API available on macOS 26 (Tahoe).
/// This is a stub implementation as the required APIs are not yet available.
/// The full implementation is disabled until macOS 26 SDK is available.
class NativeAppleTranscriptionService: TranscriptionService {
    private let logger = Logger(subsystem: "com.prakashjoshipax.voiceink", category: "NativeAppleTranscriptionService")
    
    enum ServiceError: Error, LocalizedError {
        case unsupportedOS
        
        var errorDescription: String? {
            return "Native Apple Speech transcription requires macOS 26 or later and is not available in this build."
        }
    }
    
    func transcribe(audioURL: URL, model: any TranscriptionModel) async throws -> String {
        logger.error("Native Apple transcription is not available in this build (requires macOS 26 SDK)")
        throw ServiceError.unsupportedOS
    }
}
