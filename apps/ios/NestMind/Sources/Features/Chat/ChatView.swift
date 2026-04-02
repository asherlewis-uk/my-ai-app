import PhotosUI
import SwiftUI

struct ChatView: View {
  let conversationStore: ConversationStore
  @State private var composerText = ""
  @State private var selectedPhotoItem: PhotosPickerItem?

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        LazyVStack(spacing: 14) {
          hero

          if let messages = conversationStore.conversation?.messages, !messages.isEmpty {
            ForEach(messages) { message in
              MessageBubble(message: message)
            }
          } else {
            EmptyChatState()
          }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 28)
      }

      if !conversationStore.pendingAttachments.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 10) {
            ForEach(conversationStore.pendingAttachments) { attachment in
              HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                Text(attachment.localLabel)
                  .lineLimit(1)
                Button {
                  conversationStore.removeAttachment(id: attachment.id)
                } label: {
                  Image(systemName: "xmark.circle.fill")
                }
              }
              .font(.footnote.weight(.medium))
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
              .background(.ultraThinMaterial, in: Capsule())
            }
          }
          .padding(.horizontal, 18)
        }
        .padding(.bottom, 8)
      }

      if let errorMessage = conversationStore.errorMessage {
        Text(errorMessage)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.red)
          .padding(.horizontal, 18)
          .padding(.bottom, 8)
      }

      composer
    }
    .navigationTitle("Companion")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: selectedPhotoItem) { _, newValue in
      guard let newValue else { return }
      Task {
        if let data = try? await newValue.loadTransferable(type: Data.self) {
          await conversationStore.analyzeImageData(data)
        }
        selectedPhotoItem = nil
      }
    }
  }

  private var hero: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Context before advice.")
        .font(.system(size: 28, weight: .bold, design: .serif))
      Text("This conversation is backed by your profile, your accepted memories, and any photos you attach before sending.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(18)
    .background(
      LinearGradient(
        colors: [Color.white.opacity(0.7), Color(red: 0.90, green: 0.94, blue: 0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      ),
      in: RoundedRectangle(cornerRadius: 28, style: .continuous)
    )
  }

  private var composer: some View {
    HStack(alignment: .bottom, spacing: 12) {
      PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
        Image(systemName: "photo.on.rectangle.angled")
          .font(.title3)
          .foregroundStyle(Color(red: 0.12, green: 0.27, blue: 0.24))
          .frame(width: 42, height: 42)
          .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      }

      TextField("How should NestMind help right now?", text: $composerText, axis: .vertical)
        .textFieldStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

      Button {
        let outgoing = composerText
        composerText = ""
        Task {
          await conversationStore.sendMessage(outgoing)
        }
      } label: {
        Image(systemName: conversationStore.isSending ? "hourglass" : "arrow.up")
          .font(.headline)
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background(Color(red: 0.12, green: 0.27, blue: 0.24), in: Circle())
      }
      .disabled((composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && conversationStore.pendingAttachments.isEmpty) || conversationStore.isSending)
    }
    .padding(18)
    .background(.thinMaterial)
  }
}

private struct EmptyChatState: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Start your first thread")
        .font(.headline)
      Text("Ask for reflection, planning, or perspective. Attach a photo when the visual context matters.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(18)
    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }
}

private struct MessageBubble: View {
  let message: ChatMessage

  var body: some View {
    HStack {
      if message.role == .assistant {
        bubble
        Spacer(minLength: 32)
      } else {
        Spacer(minLength: 32)
        bubble
      }
    }
  }

  private var bubble: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(message.role == .assistant ? "NestMind" : "You")
        .font(.caption.weight(.semibold))
        .foregroundStyle(secondaryTextColor)
      Text(message.content)
        .font(.body)
        .foregroundStyle(primaryTextColor)
      if let reasoning = message.reasoning, !reasoning.isEmpty {
        Text(reasoning)
          .font(.footnote)
          .foregroundStyle(secondaryTextColor)
      }
      if !message.attachments.isEmpty {
        ForEach(message.attachments) { attachment in
          Label(attachment.analysisSummary ?? "Photo attached", systemImage: "photo")
            .font(.footnote)
            .foregroundStyle(secondaryTextColor)
        }
      }
    }
    .padding(14)
    .background(backgroundColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
  }

  private var backgroundColor: Color {
    message.role == .assistant
      ? Color.white.opacity(0.82)
      : Color(red: 0.16, green: 0.31, blue: 0.28).opacity(0.88)
  }

  private var primaryTextColor: Color {
    message.role == .assistant ? .primary : .white
  }

  private var secondaryTextColor: Color {
    message.role == .assistant ? .secondary : Color.white.opacity(0.78)
  }
}
