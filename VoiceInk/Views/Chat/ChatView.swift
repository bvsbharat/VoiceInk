import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatConversation.updatedAt, order: .reverse) private var conversations: [ChatConversation]
    
    @State private var currentConversation: ChatConversation?
    @State private var showModelPicker = false
    @State private var selectedProvider: AIProvider?
    @State private var selectedModelId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            if let conversation = currentConversation {
                // Chat interface with conversation
                ChatConversationView(conversation: conversation)
            } else {
                // Welcome screen with model selection
                welcomeView
            }
        }
        .sheet(isPresented: $showModelPicker) {
            NewChatSheet(isPresented: $showModelPicker, selectedProvider: $selectedProvider, selectedModelId: $selectedModelId)
                .onDisappear {
                    if let provider = selectedProvider, let modelId = selectedModelId {
                        createNewConversation(provider: provider, modelId: modelId)
                        selectedProvider = nil
                        selectedModelId = nil
                    }
                }
        }
        .onAppear {
            // Auto-select the most recent conversation or create a default one
            if currentConversation == nil {
                if let recent = conversations.first {
                    currentConversation = recent
                } else {
                    // Check if we have any configured providers
                    let availableProviders = getAvailableProviders()
                    if let firstProvider = availableProviders.first {
                        // Auto-create a conversation with the first available provider
                        let conversation = ChatConversation(
                            provider: firstProvider,
                            modelId: firstProvider.defaultModel
                        )
                        modelContext.insert(conversation)
                        currentConversation = conversation
                    }
                }
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon and welcome message
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(.blue.gradient)
                
                Text("What can I help you with?")
                    .font(.system(size: 32, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Model selector button at bottom
            Button(action: { showModelPicker = true }) {
                HStack {
                    Image(systemName: "brain")
                    Text("Select AI Model")
                    Image(systemName: "chevron.down")
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    private func getAvailableProviders() -> [AIProvider] {
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
    
    private func createNewConversation(provider: AIProvider, modelId: String) {
        let conversation = ChatConversation(provider: provider, modelId: modelId)
        modelContext.insert(conversation)
        currentConversation = conversation
    }
    
    private func deleteConversation(_ conversation: ChatConversation) {
        modelContext.delete(conversation)
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
}

struct ConversationRow: View {
    let conversation: ChatConversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
            Text(conversation.updatedAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct NewChatSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedProvider: AIProvider?
    @Binding var selectedModelId: String?
    
    var availableProviders: [AIProvider] {
        AIProvider.allCases.filter { provider in
            // Only show providers that support chat and have API keys
            switch provider {
            case .deepgram, .elevenLabs, .soniox, .ollama, .custom:
                return false
            default:
                let apiKey = getAPIKey(for: provider)
                return !apiKey.isEmpty
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !availableProviders.isEmpty {
                    Section {
                        ForEach(availableProviders, id: \.self) { provider in
                            NavigationLink(destination: ModelSelectionView(
                                provider: provider,
                                selectedProvider: $selectedProvider,
                                selectedModelId: $selectedModelId,
                                isPresented: $isPresented
                            )) {
                                HStack {
                                    Image(systemName: "brain")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text(provider.rawValue)
                                            .font(.headline)
                                        Text("\(provider.availableModels.count) models")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Select AI Provider")
                    }
                } else {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("No AI Providers Available")
                                .font(.headline)
                            Text("Configure an AI provider in AI Models settings. Supported providers: OpenAI, Anthropic, Groq, Gemini, Cerebras, Mistral, OpenRouter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
            .navigationTitle("New Chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
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
}

struct ModelSelectionView: View {
    let provider: AIProvider
    @Binding var selectedProvider: AIProvider?
    @Binding var selectedModelId: String?
    @Binding var isPresented: Bool
    
    var body: some View {
        List {
            ForEach(provider.availableModels, id: \.self) { model in
                Button(action: {
                    selectedProvider = provider
                    selectedModelId = model
                    isPresented = false
                }) {
                    HStack {
                        Text(model)
                            .font(.body)
                        Spacer()
                        if model == provider.defaultModel {
                            Text("Default")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Select Model")
    }
}
