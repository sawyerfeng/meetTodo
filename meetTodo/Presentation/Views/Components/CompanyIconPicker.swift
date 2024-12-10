import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CompanyIconPicker: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    
    // 内置图标列表
    private let builtInIcons = [
        "building.2.fill",
        "building.columns.fill",
        "building.fill",
        "building.2.crop.circle.fill",
        "laptopcomputer",
        "desktopcomputer",
        "network",
        "antenna.radiowaves.left.and.right",
        "cloud.fill",
        "gear.circle.fill",
        "cube.fill",
        "square.stack.3d.up.fill"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // 当前选中的图片（如果有）
                if let image = selectedImage {
                    Section("当前图片") {
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                
                // 内置图标
                Section("内置图标") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(builtInIcons, id: \.self) { iconName in
                            Button {
                                selectedIcon = iconName
                                selectedImage = nil
                                dismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: iconName)
                                        .font(.system(size: 40))
                                        .foregroundColor(selectedIcon == iconName ? .white : .blue)
                                        .frame(width: 80, height: 80)
                                        .background(selectedIcon == iconName ? Color.blue : Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .listRowBackground(Color.clear)
                }
                
                // 上传自定义图片
                Section {
                    Button {
                        showingImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.fill")
                            Text("从相册选择")
                        }
                    }
                }
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
} 