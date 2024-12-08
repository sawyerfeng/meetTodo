import SwiftUI
import SwiftData

enum InterviewStage: String, Codable, Identifiable, CaseIterable {
    case resume = "简历投递"
    case written = "笔试"
    case interview = "面试"
    case hrInterview = "HR面"
    case offer = "Offer"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .resume: return "doc.text.fill"
        case .written: return "pencil.line"
        case .interview: return "person.fill"
        case .hrInterview: return "person.text.rectangle.fill"
        case .offer: return "checkmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .resume: return .blue
        case .written: return .orange
        case .interview: return .green
        case .hrInterview: return .purple
        case .offer: return .red
        }
    }
}

enum StageStatus: String {
    case pending = "待处理"
    case passed = "通过"
    case failed = "未通过"
    
    var color: Color {
        switch self {
        case .pending: return Color.gray.opacity(0.1)
        case .passed: return Color.green.opacity(0.1)
        case .failed: return Color.red.opacity(0.1)
        }
    }
}

struct InterviewStageItem: Identifiable, Equatable {
    var id: UUID
    var stage: InterviewStage
    var interviewRound: Int?
    var date: Date
    var note: String
    var status: StageStatus
    
    var displayName: String {
        if stage == .interview, let round = interviewRound {
            return "第\(round)面"
        }
        return stage.rawValue
    }
    
    init(id: UUID = UUID(),
         stage: InterviewStage,
         interviewRound: Int? = nil,
         date: Date = Date(),
         note: String = "",
         status: StageStatus = .pending) {
        self.id = id
        self.stage = stage
        self.interviewRound = interviewRound
        self.date = date
        self.note = note
        self.status = status
    }
    
    static func == (lhs: InterviewStageItem, rhs: InterviewStageItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.stage == rhs.stage &&
        lhs.interviewRound == rhs.interviewRound &&
        lhs.date == rhs.date &&
        lhs.note == rhs.note &&
        lhs.status == rhs.status
    }
}

struct CompanyDetailView: View {
    let item: Item
    @Environment(\.modelContext) private var modelContext
    @State private var stages: [InterviewStageItem] = []
    @State private var showingStageSelector = false
    @State private var showingNoteEditor = false
    @State private var selectedStage: InterviewStageItem?
    @State private var showingFailureAlert = false
    
    var availableStages: [InterviewStage] {
        let existingStages = Set(stages.map { $0.stage })
        let hasResume = existingStages.contains(.resume)
        let hasWritten = existingStages.contains(.written)
        let hasInterview = existingStages.contains(.interview)
        let hasOffer = existingStages.contains(.offer)
        
        return InterviewStage.allCases.filter { stage in
            switch stage {
            case .resume:
                return !hasResume
            case .written:
                return hasResume && !hasWritten  // 简历投递后可以笔试
            case .interview:
                return hasResume && !hasOffer  // 简历投递后随时可以面试，直到拿到offer
            case .hrInterview:
                return hasInterview && !hasOffer  // 有面试后可以HR面
            case .offer:
                return hasResume && !hasOffer  // 只要投了简历，随时可以发offer
            }
        }
    }
    
    var body: some View {
        List {
            // 公司信息头部
            HStack {
                Image(systemName: item.companyIcon)
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading) {
                    Text(item.companyName)
                        .font(.title2.bold())
                    Text(item.currentStage)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .listRowInsets(EdgeInsets())
            .padding()
            .listRowBackground(Color.clear)
            
            // 阶段列表
            ForEach(Array(stages.enumerated()), id: \.element.id) { index, stageItem in
                StageRow(
                    item: stageItem,
                    previousStage: index > 0 ? stages[index - 1] : nil,
                    onAction: { action in
                        handleStageAction(stageItem, action)
                    }
                )
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
                .listRowBackground(Color.clear)
            }
            
            // 添加其他阶段按钮
            if !availableStages.isEmpty {
                Button {
                    showingStageSelector = true
                } label: {
                    Label("添加阶段", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingStageSelector) {
            StageSelectorView(stages: availableStages) { selectedStage in
                let interviewRound = selectedStage == .interview ?
                    (stages.filter { $0.stage == .interview }.count + 1) : nil
                
                let newStage = InterviewStageItem(
                    stage: selectedStage,
                    interviewRound: interviewRound,
                    date: Date(),
                    status: .pending
                )
                withAnimation {
                    stages.append(newStage)
                    stages.sort { $0.stage.rawValue < $1.stage.rawValue }
                }
            }
        }
        .sheet(item: $selectedStage) { stage in
            NoteEditorView(note: stage.note) { newNote in
                if let index = stages.firstIndex(where: { $0.id == stage.id }) {
                    stages[index].note = newNote
                }
            }
        }
        .alert("不要灰心", isPresented: $showingFailureAlert) {
            Button("继续加油", role: .cancel) { }
        } message: {
            Text("失败是成功之母，继续努力！")
        }
        .onAppear {
            // 加载保存的阶段数据
            stages = item.stages.map { stageData in
                InterviewStageItem(
                    id: UUID(uuidString: stageData.id) ?? UUID(),
                    stage: InterviewStage(rawValue: stageData.stage) ?? .resume,
                    interviewRound: stageData.interviewRound,
                    date: stageData.date,
                    note: stageData.note,
                    status: StageStatus(rawValue: stageData.status) ?? .pending
                )
            }
        }
        .onChange(of: stages) { _, newStages in
            // 保存阶段数据到 Item
            item.stages = newStages.map { stage in
                InterviewStageData(
                    id: stage.id.uuidString,
                    stage: stage.stage.rawValue,
                    interviewRound: stage.interviewRound,
                    date: stage.date,
                    note: stage.note,
                    status: stage.status.rawValue
                )
            }
            
            // 更新 Item 的当前阶段和状态
            updateItemStatus()
        }
    }
    
    private func handleStageAction(_ stage: InterviewStageItem, _ action: StageRowAction) {
        guard let index = stages.firstIndex(where: { $0.id == stage.id }) else { return }
        
        switch action {
        case .setStatus(let newStatus):
            withAnimation {
                stages[index].status = newStatus
                if newStatus == .failed {
                    showingFailureAlert = true
                }
                updateItemStatus()
            }
        case .editNote:
            selectedStage = stages[index]
        }
    }
    
    private func updateItemStatus() {
        // 检查是否有失败的阶段
        if let failedStage = stages.first(where: { $0.status == .failed }) {
            item.currentStage = "\(failedStage.displayName)未通过"
            item.status = .failed
            item.nextStageDate = nil
            return
        }
        
        // 检查是否有未完成的阶段
        if let currentStage = stages.first(where: { $0.status == .pending }) {
            item.currentStage = currentStage.displayName
            updateStatusForStage(currentStage)
            item.nextStageDate = currentStage.date
            return
        }
        
        // 如果所有阶段都通过，使用最后一个阶段的状态
        if let lastStage = stages.last {
            item.currentStage = "\(lastStage.displayName)已通过"
            updateStatusForStage(lastStage)
            item.nextStageDate = nil
        } else {
            item.currentStage = "未开始"
            item.status = .pending
            item.nextStageDate = nil
        }
    }
    
    private func updateStatusForStage(_ stage: InterviewStageItem) {
        switch stage.stage {
        case .resume:
            item.status = .resume
        case .written:
            item.status = .written
        case .interview:
            if let round = stage.interviewRound {
                switch round {
                case 1: item.status = .interview1
                case 2: item.status = .interview2
                default: item.status = .interview3
                }
            } else {
                item.status = .interview1
            }
        case .hrInterview:
            item.status = .hrInterview
        case .offer:
            item.status = stage.status == .passed ? .offer : .hrInterview
        }
    }
}

enum StageRowAction {
    case setStatus(StageStatus)
    case editNote
}

struct StageRow: View {
    let item: InterviewStageItem
    let previousStage: InterviewStageItem?
    let onAction: (StageRowAction) -> Void
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 连接线
            if let _ = previousStage {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 2, height: 20)
                    .padding(.vertical, 4)
            }
            
            // 主要内容
            HStack(spacing: 12) {
                Circle()
                    .fill(item.stage.color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: item.stage.icon)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.headline)
                    Text(item.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button {
                    showingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(item.status.color)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .confirmationDialog("选择操作", isPresented: $showingActionSheet, titleVisibility: .hidden) {
            Button("添加笔记") {
                onAction(.editNote)
            }
            
            Button("标记为通过", role: .none) {
                onAction(.setStatus(.passed))
            }
            
            Button("标记为未通过", role: .destructive) {
                onAction(.setStatus(.failed))
            }
            
            Button("取消", role: .cancel) { }
        }
    }
}

struct StageSelectorView: View {
    let stages: [InterviewStage]
    let onSelect: (InterviewStage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(stages) { stage in
                Button {
                    onSelect(stage)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: stage.icon)
                            .foregroundColor(stage.color)
                        Text(stage.rawValue)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("选择阶段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NoteEditorView: View {
    let note: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var noteContent: String = ""
    
    init(note: String, onSave: @escaping (String) -> Void) {
        self.note = note
        self.onSave = onSave
        _noteContent = State(initialValue: note)
    }
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $noteContent)
                .padding()
                .navigationTitle("笔记")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("保存") {
                            onSave(noteContent)
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    NavigationStack {
        CompanyDetailView(item: Item(
            companyName: "阿里巴巴",
            companyIcon: "building.2.fill",
            processType: .application,
            currentStage: "简历投递",
            status: .resume
        ))
    }
} 
