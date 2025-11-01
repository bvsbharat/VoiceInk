import SwiftUI

struct MultimodalMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display images if present
            if let imageData = message.imageData,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 400, maxHeight: 400)
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
            
            // Display text content
            if !message.content.isEmpty {
                switch message.contentType {
                case .text, .multimodal:
                    if message.role == .user {
                        Text(message.content)
                            .textSelection(.enabled)
                    } else {
                        MarkdownWebView(markdown: message.content)
                            .frame(height: calculateHeight(for: message.content))
                            .allowsHitTesting(false)
                    }
                case .image:
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                case .audio:
                    HStack {
                        Image(systemName: "waveform")
                        Text("Audio message")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func calculateHeight(for content: String) -> CGFloat {
        let lines = content.components(separatedBy: .newlines).count
        let codeBlocks = content.components(separatedBy: "```").count / 2
        
        let baseHeight: CGFloat = 100
        let lineHeight: CGFloat = 20
        let codeBlockHeight: CGFloat = 200
        
        return baseHeight + (CGFloat(lines) * lineHeight) + (CGFloat(codeBlocks) * codeBlockHeight)
    }
}
