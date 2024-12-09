import SwiftUI

struct IconPickerView: View {
    let selectedIcon: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let icons = [
        "building.2.fill",
        "building.columns.fill",
        "building.fill",
        "building.2.crop.circle.fill",
        "building.columns.circle.fill",
        "briefcase.fill",
        "case.fill",
        "doc.text.fill",
        "doc.fill",
        "doc.circle.fill",
        "doc.badge.gearshape.fill",
        "doc.badge.clock.fill",
        "folder.fill",
        "folder.circle.fill",
        "graduationcap.fill",
        "book.fill",
        "books.vertical.fill",
        "bookmark.fill",
        "bookmark.circle.fill",
        "star.fill",
        "star.circle.fill",
        "heart.fill",
        "heart.circle.fill",
        "lightbulb.fill",
        "lightbulb.circle.fill",
        "target",
        "scope",
        "flag.fill",
        "flag.circle.fill",
        "checkmark.seal.fill",
        "checkmark.circle.fill",
        "rosette",
        "medal.fill",
        "crown.fill",
        "trophy.fill",
        "gift.fill",
        "sparkles",
        "wand.and.stars",
        "bolt.fill",
        "bolt.circle.fill"
    ]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            onSelect(icon)
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(icon == selectedIcon ? .blue : .gray)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(icon == selectedIcon ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
} 