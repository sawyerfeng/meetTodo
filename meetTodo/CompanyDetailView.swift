import SwiftUI
import SwiftData

enum InterviewStage: String, Codable, Identifiable, CaseIterable {
    case resume = "投递"
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
        ZStack {
            List {
                // 公司信息头部
                HStack(spacing: 16) {
                    // 公司图标
                    ZStack {
                        Image(systemName: item.companyIcon)
                            .font(.title)
                            .foregroundColor(.blue)
                            .frame(width: 60, height: 60)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .offset(x: 20, y: -20)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.companyName)
                            .font(.title2.bold())
                        Text(item.currentStage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                Rectangle()
                                    .fill(item.status.color)
                                    .frame(width: geometry.size.width * CGFloat(item.status.percentage) / 100, height: 4)
                                    .cornerRadius(2)
                            }
                        }
                        .frame(height: 4)
                        .padding(.top, 4)
                    }
                }
                .padding()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // 阶段列表
                let sortedStages = stages.sorted { stage1, stage2 in
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
                        // 如果是同一阶段（比如面试），按照轮次排序
                        if stage1.stage == .interview {
                            return (stage1.interviewRound ?? 0) < (stage2.interviewRound ?? 0)
                        }
                        return stage1.date < stage2.date
                    }
                    return index1 < index2
                }
                
                ForEach(Array(sortedStages.enumerated()), id: \.element.id) { index, stage in
                    StageRow(item: stage,
                            previousStage: index > 0 ? sortedStages[index - 1] : nil,
                            onAction: { action in
                        handleStageAction(stage, action)
                    })
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            
            // 浮动添加按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingStageSelector = true
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
        .sheet(isPresented: $showingStageSelector) {
            StageSelectorView(stages: availableStages) { stage in
                addStage(stage)
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
                // 如果是标记为通过，将之前有阶���也标记为通过
                if newStatus == .passed {
                    for i in 0...index {
                        stages[i].status = .passed
                    }
                } else {
                    stages[index].status = newStatus
                }
                
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
        
        // 获取最新的阶段（按照阶段顺序和面试轮次排序）
        let sortedStages = stages.sorted { stage1, stage2 in
            let stageOrder: [InterviewStage] = [.resume, .written, .interview, .hrInterview, .offer]
            let index1 = stageOrder.firstIndex(of: stage1.stage) ?? 0
            let index2 = stageOrder.firstIndex(of: stage2.stage) ?? 0
            
            if index1 == index2 {
                if stage1.stage == .interview {
                    return (stage1.interviewRound ?? 0) > (stage2.interviewRound ?? 0)
                }
                return stage1.date > stage2.date
            }
            return index1 > index2
        }
        
        guard let latestStage = sortedStages.first else {
            item.currentStage = "未开始"
            item.status = .pending
            item.nextStageDate = nil
            return
        }
        
        // 根据最新阶段状态更新
        switch latestStage.status {
        case .pending:
            item.currentStage = latestStage.displayName
            item.nextStageDate = latestStage.date
            updateStatusFromStage(latestStage)
            
        case .passed:
            item.currentStage = "\(latestStage.displayName)已通过"
            item.nextStageDate = nil
            updateStatusFromStage(latestStage)
            
        case .failed:
            item.currentStage = "\(latestStage.displayName)未通过"
            item.status = .failed
            item.nextStageDate = nil
        }
    }
    
    private func updateStatusFromStage(_ stage: InterviewStageItem) {
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
    
    private func addStage(_ stage: InterviewStage) {
        // 获取阶段顺序
        let stageOrder: [InterviewStage] = [
            .resume,
            .written,
            .interview,
            .hrInterview,
            .offer
        ]
        
        // 获取新阶段的索引
        let newStageIndex = stageOrder.firstIndex(of: stage) ?? 0
        
        // 自动将之前的所有阶段标记为通过
        for existingStage in stages {
            if let existingIndex = stageOrder.firstIndex(of: existingStage.stage),
               existingIndex < newStageIndex {
                if let index = stages.firstIndex(where: { $0.id == existingStage.id }) {
                    stages[index].status = .passed
                }
            }
        }
        
        // 添加新阶段
        var newStage = InterviewStageItem(stage: stage)
        
        // 如果是面试阶段，计算当前轮次
        if stage == .interview {
            let currentRound = stages.filter { $0.stage == .interview }.count + 1
            newStage.interviewRound = currentRound
        }
        
        withAnimation {
            stages.append(newStage)
            updateItemStatus()
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
    
    var formattedDate: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: item.date)
    }
    
    var formattedDay: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy年MM月dd日"
        return dayFormatter.string(from: item.date)
    }
    
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
                    Text(formattedDay)
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
                
                // 时间显示
                Text(formattedDate)
                    .font(.title3.bold())
                    .foregroundColor(item.stage.color)
                    .frame(minWidth: 60)
                
                Button {
                    showingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(item.status.color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .confirmationDialog("选择操作", isPresented: $showingActionSheet) {
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
    @State private var selectedDate = Date()
    @State private var selectedStage: InterviewStage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 阶段选择
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(stages) { stage in
                            Button {
                                selectedStage = stage
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: stage.icon)
                                        .font(.title2)
                                    Text(stage.rawValue)
                                        .font(.caption)
                                }
                                .foregroundColor(selectedStage == stage ? stage.color : .gray)
                                .frame(width: 60, height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedStage == stage ? stage.color.opacity(0.1) : Color.gray.opacity(0.1))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 时间选择
                DatePicker("选择时间", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    .padding(.horizontal)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                
                // 添加按钮
                Button {
                    if let stage = selectedStage {
                        onSelect(stage)
                    }
                    dismiss()
                } label: {
                    Text("添加")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedStage == nil ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(selectedStage == nil)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
            .navigationTitle("添加阶段")
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
            currentStage: "投递",
            status: .resume
        ))
    }
} 
