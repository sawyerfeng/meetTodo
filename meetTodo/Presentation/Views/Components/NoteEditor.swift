import SwiftUI

struct NoteEditor: View {
    let note: String
    let onSave: (String) -> Void
    
    @State private var editedNote: String
    @Environment(\.dismiss) private var dismiss
    
    init(note: String, onSave: @escaping (String) -> Void) {
        self.note = note
        self.onSave = onSave
        self._editedNote = State(initialValue: note)
    }
    
    var body: some View {
        Form {
            Section {
                TextEditor(text: $editedNote)
                    .frame(minHeight: 200)
            }
            
            Section {
                Button("保存") {
                    onSave(editedNote)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    NavigationView {
        NoteEditor(
            note: "这是一个测试笔记",
            onSave: { _ in }
        )
        .navigationTitle("编辑笔记")
        .navigationBarTitleDisplayMode(.inline)
    }
} 