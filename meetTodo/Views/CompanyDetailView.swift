import SwiftUI
import SwiftData

struct CompanyDetailView: View {
    @StateObject private var viewModel: CompanyDetailViewModel
    @State private var selectedStage: InterviewStageItem?
    
    init(item: Item) {
        self._viewModel = StateObject(wrappedValue: CompanyDetailViewModel(item: item))
    }
    
    // 获取排序后的阶段列表
    private var sortedStages: [InterviewStageItem] {
        viewModel.stages.sorted { stage1, stage2 in
            let stageOrder: [InterviewStage] = [
                .resume,
                .written,
                .interview,
                .hrInterview,
                .offer
            ]
            
            let index1 = stageOrder.firstIndex(of: stage1.stage) ?? 0
            let index2 = stageOrder.firstIndex(of: stage2.stage) ?? 0
            
            if index1 == index2 {
                if stage1.stage == .interview {
                    return (stage1.interviewRound ?? 0) < (stage2.interviewRound ?? 0)
                }
                return stage1.date < stage2.date
            }
            return index1 < index2
        }
    }
    
    // 构建阶段行视图
    private func buildStageRow(stage: InterviewStageItem, index: Int) -> some View {
        StageRow(
            item: stage,
            selectedStage: $selectedStage,
            onAction: { action in
                viewModel.handleStageAction(stage, action)
            }
        )
        .listRowInsets(EdgeInsets())
        .padding(.horizontal)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 公司信息头部
                    VStack(spacing: 20) {
                        // 公司图标
                        Button {
                            viewModel.showingIconPicker = true
                        } label: {
                            ZStack {
                                if let image = viewModel.selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                } else {
                                    viewModel.icon
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            makeTextField(viewModel.companyName, isEditing: viewModel.isEditingName) { newValue in
                                viewModel.updateCompanyName(newValue)
                            }
                            
                            Text(viewModel.currentStage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // 进度条
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    Rectangle()
                                        .fill(viewModel.statusColor)
                                        .frame(width: geometry.size.width * viewModel.progressPercentage, height: 4)
                                        .cornerRadius(2)
                                }
                            }
                            .frame(height: 4)
                            .padding(.top, 4)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding()
                    
                    // 阶段列表
                    ForEach(Array(sortedStages.enumerated()), id: \.element.id) { index, stage in
                        buildStageRow(stage: stage, index: index)
                    }
                }
            }
            
            // 浮动添加按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.showingAddStageSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4, y: 2)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("公司详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedStage) { stage in
            NavigationView {
                StageEditorView(
                    stage: stage,
                    availableStages: viewModel.getAvailableStagesForEdit(stage.stage),
                    onSave: { newStage, newDate, location in
                        viewModel.handleStageAction(stage, .update(newStage, newDate, location))
                        selectedStage = nil
                    },
                    onDelete: {
                        viewModel.handleStageAction(stage, .delete)
                        selectedStage = nil
                    },
                    onSetStatus: { status in
                        viewModel.handleStageAction(stage, .setStatus(status))
                    }
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $viewModel.showingIconPicker) {
            IconPickerView(selectedIcon: viewModel.iconName) { icon in
                viewModel.updateSystemIcon(icon)
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(image: Binding(
                get: { viewModel.selectedImage },
                set: { viewModel.updateIcon($0!) }
            ))
        }
        .sheet(isPresented: $viewModel.showingAddStageSheet) {
            AddStageView(availableStages: viewModel.getAvailableStages()) { stage, date, location in
                viewModel.addStage(stage: stage, date: date, location: location)
            }
        }
        .alert("面试失败", isPresented: $viewModel.showingFailureAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("很遗憾未能通过这一轮面试，继续加油！")
        }
    }
    
    @ViewBuilder
    private func makeTextField(_ text: String, isEditing: Bool, onCommit: @escaping (String) -> Void) -> some View {
        if isEditing {
            TextField("公司名称", text: .constant(text))
                .font(.title2.bold())
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .onSubmit {
                    onCommit(text)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
        } else {
            Button {
                viewModel.isEditingName = true
            } label: {
                Text(text)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            }
        }
    }
} 