import SwiftUI

struct EnhancedChatInput: View {
    @Binding var messageText: String
    let isLoading: Bool
    let currentProvider: AIProvider
    let currentModel: String
    let onSend: () -> Void
    let onModelChange: () -> Void
    let onImageAttached: ((Data) -> Void)?
    
    @State private var showAttachmentMenu = false
    @State private var isRecording = false
    @State private var showImagePicker = false
    @State private var attachedImage: NSImage?
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .bottom, spacing: 12) {
                // Attachment button
                Button(action: { showImagePicker = true }) {
                    Image(systemName: attachedImage != nil ? "photo.fill" : "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(attachedImage != nil ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .fileImporter(
                    isPresented: $showImagePicker,
                    allowedContentTypes: [.image],
                    allowsMultipleSelection: false
                ) { result in
                    handleImageSelection(result)
                }
                
                // Text input area
                VStack(alignment: .leading, spacing: 8) {
                    // Model selector bar
                    Button(action: onModelChange) {
                        HStack(spacing: 6) {
                            Image(systemName: "brain")
                                .font(.system(size: 12))
                            Text("\(currentProvider.rawValue)")
                                .font(.system(size: 12, weight: .medium))
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(currentModel)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    // Text editor
                    TextEditor(text: $messageText)
                        .frame(minHeight: 35, maxHeight: 96)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                // Voice input button
                Button(action: { isRecording.toggle() }) {
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isRecording ? .red : .secondary)
                }
                .buttonStyle(.plain)
                
                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(canSend ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!canSend || isLoading)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.windowBackgroundColor))
        }
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || attachedImage != nil
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            if let imageData = try? Data(contentsOf: url),
               let image = NSImage(data: imageData) {
                attachedImage = image
                onImageAttached?(imageData)
            }
        case .failure(let error):
            print("Image selection failed: \(error)")
        }
    }
}
