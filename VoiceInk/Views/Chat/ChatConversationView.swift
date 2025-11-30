import SwiftUI
import SwiftData

struct ChatConversationView: View {
    let conversation: ChatConversation
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allMessages: [ChatMessage]
    
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var attachedImageData: Data?
    @State private var showModelPicker = false
    @State private var selectedProvider: AIProvider
    @State private var selectedModel: String
    
    init(conversation: ChatConversation) {
        self.conversation = conversation
        _selectedProvider = State(initialValue: conversation.provider)
        _selectedModel = State(initialValue: conversation.modelId)
    }
    
    private var messages: [ChatMessage] {
        allMessages.filter { $0.conversationId == conversation.id }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Welcome message for empty conversations
                        if messages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.blue.gradient)
                                Text("Start a conversation")
                                    .font(.title3.weight(.semibold))
                                Text("Ask me anything!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        }
                        
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                HStack(spacing: 8) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(Color.secondary)
                                            .frame(width: 8, height: 8)
                                            .scaleEffect(isLoading ? 1.0 : 0.5)
                                            .animation(
                                                Animation.easeInOut(duration: 0.6)
                                                    .repeatForever()
                                                    .delay(Double(index) * 0.2),
                                                value: isLoading
                                            )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                            .id("loading")
                        }
                    }
                    .padding(.vertical, 20)
                }
                .focusable()
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom()
                }
                .onChange(of: isLoading) { _, newValue in
                    if newValue {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Error Message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Dismiss") {
                        errorMessage = nil
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            }
            
            Divider()
            
            // Input Area
            inputView
        }
        .background(Color(.windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.headline)
                Text("\(conversation.provider.rawValue) • \(conversation.modelId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Menu {
                Button(action: clearConversation) {
                    Label("Clear Messages", systemImage: "trash")
                }
                Button(action: renameConversation) {
                    Label("Rename", systemImage: "pencil")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .menuStyle(.borderlessButton)
        }
        .padding()
    }
    
    private var inputView: some View {
        EnhancedChatInput(
            messageText: $messageText,
            isLoading: isLoading,
            currentProvider: selectedProvider,
            currentModel: selectedModel,
            onSend: sendMessage,
            onModelChange: {
                showModelPicker = true
            },
            onImageAttached: { imageData in
                attachedImageData = imageData
            }
        )
        .sheet(isPresented: $showModelPicker) {
            ModelPickerView(
                selectedProvider: selectedProvider,
                selectedModel: selectedModel,
                onSelect: { provider, modelId in
                    selectedProvider = provider
                    selectedModel = modelId
                    showModelPicker = false
                }
            )
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty || attachedImageData != nil else { return }
        
        // Create user message with optional image
        let contentType: ChatMessage.ContentType = attachedImageData != nil ? .multimodal : .text
        let userMessage = ChatMessage(
            role: .user,
            content: trimmedMessage,
            conversationId: conversation.id,
            contentType: contentType,
            imageData: attachedImageData
        )
        modelContext.insert(userMessage)
        
        // Update conversation title if it's the first message
        if messages.count == 1 {
            conversation.title = String(trimmedMessage.prefix(50))
        }
        conversation.updatedAt = Date()
        
        messageText = ""
        attachedImageData = nil
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let chatService = ChatService()
                let response = try await chatService.sendMessage(
                    messages: messages,
                    provider: selectedProvider,
                    modelId: selectedModel
                )
                
                await MainActor.run {
                    let assistantMessage = ChatMessage(role: .assistant, content: response, conversationId: conversation.id)
                    modelContext.insert(assistantMessage)
                    conversation.updatedAt = Date()
                    isLoading = false
                    scrollToBottom()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func scrollToBottom() {
        if let lastMessage = messages.last {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func clearConversation() {
        for message in messages {
            modelContext.delete(message)
        }
    }
    
    private func renameConversation() {
        // TODO: Implement rename dialog
    }
}
