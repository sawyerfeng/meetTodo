import SwiftUI

struct StageDetailView: View {
    @StateObject private var viewModel: StageDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    init(item: InterviewStageItem, availableStages: [InterviewStage], onAction: @escaping (StageRowAction) -> Void) {
        self._viewModel = StateObject(wrappedValue: StageDetailViewModel(
            item: item,
            availableStages: availableStages,
            onAction: onAction
        ))
    }
    
    var body: some View {
        List {
            // 阶段信息
            Section {
                let item = viewModel.getItem()
                HStack(spacing: 16) {
                    Circle()
                        .fill(item.stage.color)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: item.stage.icon)
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.displayName)
                            .font(.title2.bold())
                        
                        Text(viewModel.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                
                // 地点信息（如果有）
                if let location = item.location {
                    Button {
                        viewModel.showingMapActionSheet = true
                    } label: {
                        HStack {
                            Image(systemName: location.type == .online ? "link" : "mappin.and.ellipse")
                                .foregroundColor(.blue)
                            Text(location.address)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // 状态信息
            Section {
                let item = viewModel.getItem()
                HStack {
                    Text("当前状态")
                    Spacer()
                    Text(item.status.rawValue)
                        .foregroundColor(.secondary)
                }
            }
            
            // 备注信息
            if !viewModel.getItem().note.isEmpty {
                Section("备注") {
                    Text(viewModel.getItem().note)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("阶段详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingEditor = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingEditor) {
            let item = viewModel.getItem()
            StageEditorView(
                stage: item,
                availableStages: viewModel.getAvailableStages(),
                onSave: { newStage, newDate, location in
                    viewModel.handleAction(.update(newStage, newDate, location))
                    dismiss()
                },
                onDelete: {
                    viewModel.handleAction(.delete)
                    dismiss()
                },
                onSetStatus: { status in
                    viewModel.handleAction(.setStatus(status))
                    dismiss()
                }
            )
        }
        .confirmationDialog("选择地图应用", isPresented: $viewModel.showingMapActionSheet) {
            if let location = viewModel.getItem().location {
                Button("在高德地图中打开") {
                    viewModel.openInAmap(address: location.address)
                }
                Button("在苹果地图中打开") {
                    viewModel.openInAppleMaps(address: location.address)
                }
                Button("取消", role: .cancel) { }
            }
        }
    }
} 