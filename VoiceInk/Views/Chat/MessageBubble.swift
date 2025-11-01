import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    private var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !isUser {
                avatarView
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                // Message content with multimodal support
                if isUser {
                    // User messages with image support
                    VStack(alignment: .leading, spacing: 8) {
                        if let imageData = message.imageData,
                           let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 300, maxHeight: 300)
                                .cornerRadius(12)
                        }
                        if !message.content.isEmpty {
                            Text(message.content)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                } else {
                    // AI messages with syntax highlighting and image generation
                    VStack(alignment: .leading, spacing: 12) {
                        // Display generated images
                        if let imageData = message.imageData,
                           let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 600)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                        }
                        
                        // Display text content with markdown
                        if !message.content.isEmpty {
                            MarkdownWebView(markdown: message.content)
                                .frame(height: estimateContentHeight(for: message.content))
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(16)
                }
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            
            if isUser {
                avatarView
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var avatarView: some View {
        Image(systemName: isUser ? "person.circle.fill" : "brain.head.profile")
            .font(.title2)
            .foregroundColor(isUser ? .blue : .purple)
            .frame(width: 32, height: 32)
    }
    
    private func calculateHeight(for content: String) -> CGFloat {
        // Estimate height based on content length
        var height: CGFloat = 0
        
        // Add height for image if present
        if message.imageData != nil {
            height += 320 // Image height + padding
        }
        
        // Add height for text content
        if !content.isEmpty {
            height += calculateTextHeight(for: content)
        }
        
        return max(height, 100)
    }
    
    private func calculateTextHeight(for content: String) -> CGFloat {
        let lines = content.components(separatedBy: .newlines).count
        let codeBlocks = content.components(separatedBy: "```").count / 2
        
        let baseHeight: CGFloat = 100
        let lineHeight: CGFloat = 20
        let codeBlockHeight: CGFloat = 200
        
        return baseHeight + (CGFloat(lines) * lineHeight) + (CGFloat(codeBlocks) * codeBlockHeight)
    }
    
    private func estimateContentHeight(for content: String) -> CGFloat {
        // Count different elements
        let lines = content.components(separatedBy: .newlines).count
        let codeBlocks = content.components(separatedBy: "```").count / 2
        let headings = content.components(separatedBy: .newlines).filter { $0.hasPrefix("#") }.count
        let listItems = content.components(separatedBy: .newlines).filter { $0.hasPrefix("- ") || $0.hasPrefix("* ") }.count
        
        // Calculate heights
        var totalHeight: CGFloat = 80 // Base padding
        totalHeight += CGFloat(lines) * 24 // Line height
        totalHeight += CGFloat(codeBlocks) * 250 // Code block height
        totalHeight += CGFloat(headings) * 15 // Extra space for headings
        totalHeight += CGFloat(listItems) * 5 // Extra space for lists
        
        // Add extra height for long content
        if content.count > 1000 {
            totalHeight += CGFloat(content.count / 100) * 10
        }
        
        return max(totalHeight, 150) // Minimum height
    }
}

struct MarkdownTextView: View {
    let content: String
    let isUser: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMarkdownBlocks(), id: \.id) { block in
                switch block.type {
                case .text:
                    Text(parseInlineMarkdown(block.content))
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .code:
                    CodeBlockView(code: block.content, language: block.language)
                case .heading:
                    Text(block.content)
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private func parseMarkdownBlocks() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = content.components(separatedBy: .newlines)
        var i = 0
        var blockId = 0
        
        while i < lines.count {
            let line = lines[i]
            
            // Check for code block
            if line.hasPrefix("```") {
                let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                i += 1
                var codeLines: [String] = []
                
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                
                blocks.append(MarkdownBlock(
                    id: blockId,
                    type: .code,
                    content: codeLines.joined(separator: "\n"),
                    language: language.isEmpty ? "plaintext" : language
                ))
                blockId += 1
                i += 1
            }
            // Check for heading
            else if line.hasPrefix("###") {
                let heading = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                blocks.append(MarkdownBlock(id: blockId, type: .heading, content: heading))
                blockId += 1
                i += 1
            }
            else if line.hasPrefix("##") {
                let heading = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                blocks.append(MarkdownBlock(id: blockId, type: .heading, content: heading))
                blockId += 1
                i += 1
            }
            // Regular text
            else {
                var textLines: [String] = []
                while i < lines.count && !lines[i].hasPrefix("```") && !lines[i].hasPrefix("##") {
                    if !lines[i].isEmpty {
                        textLines.append(lines[i])
                    }
                    i += 1
                }
                
                if !textLines.isEmpty {
                    blocks.append(MarkdownBlock(
                        id: blockId,
                        type: .text,
                        content: textLines.joined(separator: "\n")
                    ))
                    blockId += 1
                }
            }
        }
        
        return blocks
    }
    
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var result = text
        
        // Handle inline code: `code`
        result = result.replacingOccurrences(
            of: "`([^`]+)`",
            with: "$1",
            options: .regularExpression
        )
        
        // Handle bold: **text**
        result = result.replacingOccurrences(
            of: "\\*\\*([^*]+)\\*\\*",
            with: "$1",
            options: .regularExpression
        )
        
        // Handle italic: *text*
        result = result.replacingOccurrences(
            of: "\\*([^*]+)\\*",
            with: "$1",
            options: .regularExpression
        )
        
        var attributed = AttributedString(result)
        return attributed
    }
}

struct MarkdownBlock: Identifiable {
    let id: Int
    let type: BlockType
    let content: String
    var language: String = ""
    
    enum BlockType {
        case text
        case code
        case heading
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Language label with copy button
            HStack {
                if !language.isEmpty && language != "plaintext" {
                    Text(language.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Code content with line numbers
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(Array(code.components(separatedBy: .newlines).enumerated()), id: \.offset) { index, _ in
                            Text("\(index + 1)")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.6))
                                .frame(minWidth: 30, alignment: .trailing)
                                .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, 8)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                    
                    // Code text
                    Text(code)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
            .frame(maxHeight: 400)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
