import SwiftUI
import SwiftData

struct CompanyDetailView: View {
    @ObservedObject private(set) var viewModel: CompanyDetailViewModel
    
    init(item: Item, modelContext: ModelContext) {
        self._viewModel = ObservedObject(wrappedValue: CompanyDetailViewModel(modelContext: modelContext, item: item))
    }
    
    var body: some View {
        mainContent
            .navigationDestination(isPresented: $viewModel.showingStageDetail) {
                stageDetailDestination
            }
            .sheet(isPresented: $viewModel.showingStageSelector) {
                stageSelectorSheet
            }
            .sheet(item: $viewModel.selectedStage) { stage in
                noteEditorSheet(stage)
            }
            .sheet(isPresented: $viewModel.showingIconPicker) {
                CompanyIconPicker(selectedImage: $viewModel.selectedImage, selectedIcon: $viewModel.selectedIcon)
            }
            .onChange(of: viewModel.selectedImage) { oldValue, newValue in
                handleImageChange(newValue)
            }
            .onChange(of: viewModel.selectedIcon) { oldValue, newValue in
                handleIconChange(newValue)
            }
            .alert("不要灰心", isPresented: $viewModel.showingFailureAlert) {
                Button("继续加油", role: .cancel) { }
            } message: {
                Text("失败是成功之母，继续努力")
            }
            .onAppear {
                viewModel.loadStages()
            }
            .onChange(of: viewModel.stages) { oldValue, newValue in
                viewModel.saveStages(newValue)
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .top) {
            companyInfoCard
            stagesList
            addButton
        }
    }
    
    @ViewBuilder
    private var companyInfoCard: some View {
        VStack {
            VStack(spacing: 8) {
                companyIcon
                companyName
                companyStatus
                progressBar
            }
            .padding()
            .background(viewModel.getStatusColor(for: viewModel.item))
            .cornerRadius(16)
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .zIndex(1)
    }
    
    @ViewBuilder
    private var companyIcon: some View {
        ZStack {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else if let iconData = viewModel.item.iconData,
                      let uiImage = UIImage(data: iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: viewModel.selectedIcon)
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
            }
            
            if viewModel.item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .offset(x: 45, y: -45)
            }
        }
        .onTapGesture {
            viewModel.showingIconPicker = true
        }
    }
    
    @ViewBuilder
    private var companyName: some View {
        makeTextField(viewModel.item.companyName, isEditing: viewModel.isEditingName) { newName in
            if newName != viewModel.item.companyName {
                viewModel.item.companyName = newName
                try? viewModel.modelContext.save()
            }
            viewModel.isEditingName = false
        }
    }
    
    @ViewBuilder
    private var companyStatus: some View {
        Text(viewModel.item.currentStage)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(viewModel.item.status.color)
                    .frame(width: geometry.size.width * CGFloat(viewModel.item.status.percentage) / 100, height: 4)
                    .cornerRadius(2)
            }
        }
        .frame(height: 4)
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private var stagesList: some View {
        List {
            Section {
                Color.clear
                    .frame(height: 280)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            
            ForEach(Array(viewModel.stages.enumerated()), id: \.element.id) { index, stage in
                let stageItem = InterviewStageItem(
                    id: UUID(uuidString: stage.id) ?? UUID(),
                    stage: InterviewStage(rawValue: stage.stage) ?? .resume,
                    interviewRound: stage.interviewRound,
                    date: stage.date,
                    note: stage.note,
                    status: StageStatus(rawValue: stage.status) ?? .pending,
                    location: stage.location
                )
                
                let previousStage = index < viewModel.stages.count - 1 ? viewModel.stages[index + 1] : nil
                let previousStageItem = previousStage.map { stage in
                    InterviewStageItem(
                        id: UUID(uuidString: stage.id) ?? UUID(),
                        stage: InterviewStage(rawValue: stage.stage) ?? .resume,
                        interviewRound: stage.interviewRound,
                        date: stage.date,
                        note: stage.note,
                        status: StageStatus(rawValue: stage.status) ?? .pending,
                        location: stage.location
                    )
                }
                
                StageRow(
                    item: stageItem,
                    previousStage: previousStageItem,
                    availableStages: viewModel.getAvailableStagesForEdit(stage.stage),
                    onAction: { action in
                        viewModel.handleStageAction(stage, action)
                    }
                )
                .onTapGesture {
                    viewModel.stageForDetail = stage
                    viewModel.showingStageDetail = true
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    stageSwipeActions(for: stage)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            Color.clear
                .frame(height: 100)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .zIndex(0)
    }
    
    @ViewBuilder
    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.showingStageSelector = true
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
        .zIndex(2)
    }
    
    @ViewBuilder
    private var stageDetailDestination: some View {
        if let stage = viewModel.stageForDetail {
            let stageItem = InterviewStageItem(
                id: UUID(uuidString: stage.id) ?? UUID(),
                stage: InterviewStage(rawValue: stage.stage) ?? .resume,
                interviewRound: stage.interviewRound,
                date: stage.date,
                note: stage.note,
                status: StageStatus(rawValue: stage.status) ?? .pending,
                location: stage.location
            )
            
            StageDetailView(
                item: stageItem,
                availableStages: viewModel.getAvailableStagesForEdit(stage.stage),
                onAction: { action in
                    viewModel.handleStageAction(stage, action)
                    try? viewModel.modelContext.save()
                    viewModel.loadStages()
                    if case .delete = action {
                        viewModel.showingStageDetail = false
                    }
                }
            )
            .navigationBarBackButtonHidden(false)
            .interactiveDismissDisabled()
        }
    }
    
    @ViewBuilder
    private var stageSelectorSheet: some View {
        NavigationView {
            StageSelectionView(
                selectedStage: viewModel.selectedStageForAdd,
                availableStages: viewModel.getAvailableStagesForAdd(),
                onSelect: { stage in
                    viewModel.selectedStageForAdd = stage
                    viewModel.showingStageSelector = false
                    let stageData = InterviewStageData(
                        stage: stage.rawValue,
                        interviewRound: viewModel.getNextInterviewRound(for: stage)
                    )
                    viewModel.addStage(stageData)
                }
            )
            .navigationTitle("选择阶段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.showingStageSelector = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func noteEditorSheet(_ stage: InterviewStageData) -> some View {
        NavigationView {
            NoteEditor(
                note: stage.note,
                onSave: { newNote in
                    viewModel.updateStageNote(stage, newNote: newNote)
                    viewModel.selectedStage = nil
                }
            )
            .navigationTitle("编辑笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.selectedStage = nil
                    }
                }
            }
        }
    }
    
    private func handleImageChange(_ image: UIImage?) {
        guard let image = image else { return }
        if let imageData = image.jpegData(compressionQuality: 0.5) {
            viewModel.item.iconData = imageData
            try? viewModel.modelContext.save()
        }
    }
    
    private func handleIconChange(_ icon: String) {
        viewModel.item.companyIcon = icon
        try? viewModel.modelContext.save()
    }
    
    @ViewBuilder
    private func stageSwipeActions(for stage: InterviewStageData) -> some View {
        Button(role: .destructive) {
            viewModel.deleteStage(stage)
        } label: {
            Label("删除", systemImage: "trash")
        }
        
        Button {
            viewModel.selectedStage = stage
        } label: {
            Label("编辑笔记", systemImage: "note.text")
        }
        .tint(.orange)
    }
    
    @ViewBuilder
    private func makeTextField(_ text: String, isEditing: Bool, onCommit: @escaping (String) -> Void) -> some View {
        if isEditing {
            TextField("公司名称", text: .constant(text))
                .textFieldStyle(.roundedBorder)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)
                .onSubmit {
                    onCommit(text)
                }
                .onDisappear {
                    onCommit(text)
                }
        } else {
            Text(text)
                .font(.title2.bold())
                .onTapGesture {
                    viewModel.isEditingName = true
                }
        }
    }
}

#Preview {
    let modelContext = try! ModelContainer(for: Item.self).mainContext
    return NavigationStack {
        CompanyDetailView(
            item: Item(
                companyName: "阿里巴巴",
                companyIcon: "building.2.fill"
            ),
            modelContext: modelContext
        )
    }
} 
