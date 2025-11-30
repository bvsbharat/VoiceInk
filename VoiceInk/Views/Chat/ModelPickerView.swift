import SwiftUI

struct ModelPickerView: View {
    let selectedProvider: AIProvider
    let selectedModel: String
    let onSelect: (AIProvider, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentProvider: AIProvider
    @State private var currentModel: String
    
    init(selectedProvider: AIProvider, selectedModel: String, onSelect: @escaping (AIProvider, String) -> Void) {
        self.selectedProvider = selectedProvider
        self.selectedModel = selectedModel
        self.onSelect = onSelect
        _currentProvider = State(initialValue: selectedProvider)
        _currentModel = State(initialValue: selectedModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Model")
                    .font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Provider selection
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(availableProviders, id: \.self) { provider in
                        VStack(alignment: .leading, spacing: 12) {
                            // Provider header
                            HStack {
                                Image(systemName: providerIcon(for: provider))
                                    .font(.title3)
                                Text(provider.rawValue)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Models for this provider
                            ForEach(provider.availableModels, id: \.self) { model in
                                Button(action: {
                                    currentProvider = provider
                                    currentModel = model
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(model)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            if let description = modelDescription(for: model) {
                                                Text(description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if currentProvider == provider && currentModel == model {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(currentProvider == provider && currentModel == model ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Select") {
                    onSelect(currentProvider, currentModel)
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
    
    private var availableProviders: [AIProvider] {
        AIProvider.allCases.filter { provider in
            switch provider {
            case .deepgram, .elevenLabs, .soniox, .ollama, .custom:
                return false
            default:
                let apiKey = getAPIKey(for: provider)
                return !apiKey.isEmpty
            }
        }
    }
    
    private func getAPIKey(for provider: AIProvider) -> String {
        let key: String
        switch provider {
        case .openAI:
            key = "OpenAIAPIKey"
        case .anthropic:
            key = "AnthropicAPIKey"
        case .groq:
            key = "GroqAPIKey"
        case .gemini:
            key = "GeminiAPIKey"
        case .cerebras:
            key = "CerebrasAPIKey"
        case .mistral:
            key = "MistralAPIKey"
        case .openRouter:
            key = "OpenRouterAPIKey"
        default:
            return ""
        }
        return UserDefaults.standard.string(forKey: key) ?? ""
    }
    
    private func providerIcon(for provider: AIProvider) -> String {
        switch provider {
        case .openAI:
            return "brain"
        case .anthropic:
            return "sparkles"
        case .gemini:
            return "star.fill"
        case .groq:
            return "bolt.fill"
        case .cerebras:
            return "cpu"
        default:
            return "brain.head.profile"
        }
    }
    
    private func modelDescription(for model: String) -> String? {
        if model.contains("image") {
            return "Can generate images"
        } else if model.contains("pro") {
            return "Most capable"
        } else if model.contains("flash") {
            return "Fast and efficient"
        } else if model.contains("lite") {
            return "Ultra fast"
        }
        return nil
    }
}
