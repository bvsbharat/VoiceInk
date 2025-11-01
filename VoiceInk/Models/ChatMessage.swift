import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var conversationId: UUID
    var contentTypeRawValue: String = "text"
    var imageData: Data?
    var audioData: Data?
    var metadata: String? // JSON string for additional metadata
    
    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
    
    enum ContentType: String, Codable {
        case text
        case image
        case audio
        case multimodal // Text + Image
    }
    
    var contentType: ContentType {
        get { ContentType(rawValue: contentTypeRawValue) ?? .text }
        set { contentTypeRawValue = newValue.rawValue }
    }
    
    init(role: MessageRole, content: String, conversationId: UUID, contentType: ContentType = .text, imageData: Data? = nil, audioData: Data? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.conversationId = conversationId
        self.contentTypeRawValue = contentType.rawValue
        self.imageData = imageData
        self.audioData = audioData
        self.metadata = nil
    }
}

@Model
final class ChatConversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var providerRawValue: String
    var modelId: String
    
    init(title: String = "New Conversation", provider: AIProvider, modelId: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.providerRawValue = provider.rawValue
        self.modelId = modelId
    }
    
    var provider: AIProvider {
        AIProvider(rawValue: providerRawValue) ?? .openAI
    }
}
