import SwiftUI

struct MemoryListView: View {
  let memoryStore: MemoryStore
  @State private var selectedMemory: MemoryEntry?

  var body: some View {
    List {
      Section {
        Text("Accepted memories sharpen future responses without exposing another household member’s data.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .listRowBackground(Color.clear)

      ForEach(memoryStore.memories) { memory in
        Button {
          selectedMemory = memory
        } label: {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text(memory.title)
                .font(.headline)
              Spacer()
              Text(memory.kind.rawValue.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            Text(memory.summary)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.leading)

            HStack {
              Text(memory.status.rawValue.capitalized)
              Text("Confidence \(Int(memory.confidence * 100))%")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
          .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
          Button("Accept") {
            Task {
              await memoryStore.sendFeedback(id: memory.id, feedback: .accepted)
            }
          }
          .tint(.green)

          Button("Reject") {
            Task {
              await memoryStore.sendFeedback(id: memory.id, feedback: .rejected)
            }
          }
          .tint(.orange)
        }
        .swipeActions(edge: .trailing) {
          Button("Delete", role: .destructive) {
            Task {
              await memoryStore.deleteMemory(id: memory.id)
            }
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Memory")
    .sheet(item: $selectedMemory) { memory in
      MemoryEditorSheet(memoryStore: memoryStore, memory: memory)
    }
  }
}

private struct MemoryEditorSheet: View {
  let memoryStore: MemoryStore
  let memory: MemoryEntry
  @Environment(\.dismiss) private var dismiss

  @State private var title: String
  @State private var summary: String
  @State private var kind: MemoryKind
  @State private var status: MemoryStatus

  init(memoryStore: MemoryStore, memory: MemoryEntry) {
    self.memoryStore = memoryStore
    self.memory = memory
    _title = State(initialValue: memory.title)
    _summary = State(initialValue: memory.summary)
    _kind = State(initialValue: memory.kind)
    _status = State(initialValue: memory.status)
  }

  var body: some View {
    NavigationStack {
      Form {
        TextField("Title", text: $title)
        TextField("Summary", text: $summary, axis: .vertical)
          .lineLimit(4...8)
        Picker("Kind", selection: $kind) {
          ForEach(MemoryKind.allCases) { kind in
            Text(kind.rawValue.capitalized).tag(kind)
          }
        }
        Picker("Status", selection: $status) {
          ForEach(MemoryStatus.allCases) { status in
            Text(status.rawValue.capitalized).tag(status)
          }
        }
      }
      .navigationTitle("Edit memory")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            Task {
              await memoryStore.updateMemory(
                id: memory.id,
                draft: MemoryUpdateRequest(kind: kind, title: title, summary: summary, status: status)
              )
              dismiss()
            }
          }
        }
      }
    }
  }
}

