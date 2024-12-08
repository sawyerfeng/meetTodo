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
    var location: StageLocation?
    
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
         status: StageStatus = .pending,
         location: StageLocation? = nil) {
        self.id = id
        self.stage = stage
        self.interviewRound = interviewRound
        self.date = date
        self.note = note
        self.status = status
        self.location = location
    }
    
    static func == (lhs: InterviewStageItem, rhs: InterviewStageItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.stage == rhs.stage &&
        lhs.interviewRound == rhs.interviewRound &&
        lhs.date == rhs.date &&
        lhs.note == rhs.note &&
        lhs.status == rhs.status &&
        lhs.location == rhs.location
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
                            availableStages: getAvailableStagesForEdit(stage.stage),
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
            StageSelectorView(stages: availableStages) { stage, date, location in
                addStage(stage, date: date, location: location)
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
                    status: StageStatus(rawValue: stageData.status) ?? .pending,
                    location: stageData.location
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
                    status: stage.status.rawValue,
                    location: stage.location
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
                
                // 如果标记为已完成或失败，移除通知
                if newStatus != .pending {
                    let stageData = InterviewStageData(
                        id: stage.id.uuidString,
                        stage: stage.stage.rawValue,
                        interviewRound: stage.interviewRound,
                        date: stage.date,
                        note: stage.note,
                        status: stage.status.rawValue,
                        location: stage.location
                    )
                    NotificationManager.shared.removeNotification(for: item, stageData: stageData)
                }
            }
            
        case .editNote:
            selectedStage = stages[index]
            
        case .update(let newStage, let newDate, let location):
            withAnimation {
                // 如果是需要提醒的阶段，先移除旧的通知
                if [InterviewStage.interview, .written, .hrInterview].contains(stages[index].stage) {
                    let oldStageData = InterviewStageData(
                        id: stage.id.uuidString,
                        stage: stage.stage.rawValue,
                        interviewRound: stage.interviewRound,
                        date: stage.date,
                        note: stage.note,
                        status: stage.status.rawValue,
                        location: stage.location
                    )
                    NotificationManager.shared.removeNotification(for: item, stageData: oldStageData)
                }
                
                stages[index].stage = newStage
                stages[index].date = newDate
                stages[index].location = location
                
                if newStage == .interview {
                    let interviewCount = stages.filter { $0.stage == .interview }.count
                    stages[index].interviewRound = interviewCount
                } else {
                    stages[index].interviewRound = nil
                }
                updateItemStatus()
                
                // 如果新阶段需要提醒，设置新的通知
                if [InterviewStage.interview, .written, .hrInterview].contains(newStage) {
                    Task {
                        let updatedStage = stages[index]
                        await NotificationManager.shared.scheduleNotification(
                            for: item,
                            stageData: InterviewStageData(
                                id: updatedStage.id.uuidString,
                                stage: updatedStage.stage.rawValue,
                                interviewRound: updatedStage.interviewRound,
                                date: updatedStage.date,
                                note: updatedStage.note,
                                status: updatedStage.status.rawValue,
                                location: updatedStage.location
                            ),
                            minutesBefore: UserDefaults.standard.integer(forKey: "reminderMinutes")
                        )
                    }
                }
            }
            
        case .delete:
            // 移除通知
            let stageData = InterviewStageData(
                id: stage.id.uuidString,
                stage: stage.stage.rawValue,
                interviewRound: stage.interviewRound,
                date: stage.date,
                note: stage.note,
                status: stage.status.rawValue,
                location: stage.location
            )
            NotificationManager.shared.removeNotification(for: item, stageData: stageData)
            
            withAnimation {
                stages.remove(at: index)
                updateItemStatus()
            }
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
    
    private func addStage(_ stage: InterviewStage, date: Date, location: StageLocation?) {
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
        var newStage = InterviewStageItem(
            stage: stage,
            date: date,
            location: location
        )
        
        // 如果是面试阶段，计算当前轮次
        if stage == .interview {
            let currentRound = stages.filter { $0.stage == .interview }.count + 1
            newStage.interviewRound = currentRound
        }
        
        withAnimation {
            stages.append(newStage)
            updateItemStatus()
            
            // 如果是需要提醒的阶段类型，设置通知
            if [InterviewStage.interview, .written, .hrInterview].contains(stage) {
                Task {
                    await NotificationManager.shared.scheduleNotification(
                        for: item,
                        stageData: InterviewStageData(
                            id: newStage.id.uuidString,
                            stage: newStage.stage.rawValue,
                            interviewRound: newStage.interviewRound,
                            date: newStage.date,
                            note: newStage.note,
                            status: newStage.status.rawValue,
                            location: newStage.location
                        ),
                        minutesBefore: UserDefaults.standard.integer(forKey: "reminderMinutes")
                    )
                }
            }
        }
    }
    
    private func getAvailableStagesForEdit(_ currentStage: InterviewStage) -> [InterviewStage] {
        let existingStages = Set(stages.map { $0.stage })
        let hasResume = existingStages.contains(.resume)
        let hasWritten = existingStages.contains(.written)
        let hasInterview = existingStages.contains(.interview)
        let hasOffer = existingStages.contains(.offer)
        
        return InterviewStage.allCases.filter { stage in
            // 当前阶段总
            if stage == currentStage {
                return true
            }
            
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
}

enum StageRowAction {
    case setStatus(StageStatus)
    case editNote
    case update(InterviewStage, Date, StageLocation?)
    case delete
}

struct StageRow: View {
    let item: InterviewStageItem
    let previousStage: InterviewStageItem?
    let availableStages: [InterviewStage]
    let onAction: (StageRowAction) -> Void
    @State private var showingEditor = false
    
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
                    showingEditor = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(item.status.color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .sheet(isPresented: $showingEditor) {
            StageEditorView(
                stage: item,
                availableStages: availableStages,
                onSave: { newStage, newDate, location in
                    onAction(.update(newStage, newDate, location))
                },
                onDelete: {
                    onAction(.delete)
                },
                onSetStatus: { status in
                    onAction(.setStatus(status))
                }
            )
        }
    }
}

struct TimeSelectionView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 日期和时间选择器
            HStack(spacing: 8) {
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                    .labelsHidden()
                
                DatePicker("", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                    .labelsHidden()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct StageSelectorView: View {
    let stages: [InterviewStage]
    let onSelect: (InterviewStage, Date, StageLocation?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedStage: InterviewStage?
    @State private var locationType: LocationType = .online
    @State private var address: String = ""
    @State private var opacity: Double = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    // 阶段选择
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(stages) { stage in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            selectedStage = stage
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(selectedStage == stage ? stage.color : Color.gray.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                                .overlay {
                                                    Image(systemName: stage.icon)
                                                        .foregroundColor(selectedStage == stage ? .white : .gray)
                                                }
                                            Text(stage.rawValue)
                                                .font(.caption)
                                                .foregroundColor(selectedStage == stage ? stage.color : .gray)
                                        }
                                        .frame(width: 60)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("选择阶段")
                    }
                    
                    // 时间选择
                    Section {
                        TimeSelectionView(selectedDate: $selectedDate)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    
                    // 地点选择（仅面试和笔试阶段显示）
                    if let stage = selectedStage,
                       [.interview, .written, .hrInterview].contains(stage) {
                        Section {
                            VStack(spacing: 12) {
                                Picker("方式", selection: $locationType) {
                                    ForEach(LocationType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                                HStack {
                                    Image(systemName: locationType == .online ? "link" : "mappin.and.ellipse")
                                        .foregroundColor(.blue)
                                    TextField(locationType == .online ? 
                                             (stage == .written ? "笔试链接" : "会议链接") :
                                             (stage == .written ? "笔试地点" : "面试地点"),
                                             text: $address)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: locationType)
                        } header: {
                            Text(stage == .written ? "笔试方式" : "面试方式")
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .listStyle(.insetGrouped)
                
                // 底部按钮
                VStack(spacing: 16) {
                    Button {
                        if let stage = selectedStage {
                            var location: StageLocation?
                            if [.interview, .written, .hrInterview].contains(stage) {
                                location = StageLocation(type: locationType, address: address)
                            }
                            onSelect(stage, selectedDate, location)
                            dismiss()
                        }
                    } label: {
                        Text("保存")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedStage == nil ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(selectedStage == nil)
                    
                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Text("取消")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(16)
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("添加阶段")
            .navigationBarTitleDisplayMode(.inline)
            .opacity(opacity)
        }
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.75)])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
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

// 修改地点选择组件
struct LocationSelectionView: View {
    let stage: InterviewStage
    @Binding var locationType: LocationType
    @Binding var address: String
    @State private var onlineAddress: String = ""
    @State private var offlineAddress: String = ""
    
    init(stage: InterviewStage, locationType: Binding<LocationType>, address: Binding<String>) {
        self.stage = stage
        self._locationType = locationType
        self._address = address
        self._onlineAddress = State(initialValue: "")
        self._offlineAddress = State(initialValue: "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(stage == .written ? "笔试方式" : "面试方式")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("", selection: $locationType) {
                ForEach(LocationType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: locationType) { _, newValue in
                // 切换类型时保存当前地址并恢复之前的地址
                if newValue == .online {
                    offlineAddress = address
                    address = onlineAddress
                } else {
                    onlineAddress = address
                    address = offlineAddress
                }
            }
            
            HStack {
                Image(systemName: locationType == .online ? "link" : "mappin.and.ellipse")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                TextField(locationType == .online ? 
                         (stage == .written ? "笔试链接" : "会议链接") :
                         (stage == .written ? "笔试地点" : "面试地点"),
                         text: $address)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .animation(.spring(duration: 0.5, bounce: 0.3), value: stage)
    }
}

// 修改 StageEditorView
struct StageEditorView: View {
    let stage: InterviewStageItem
    let availableStages: [InterviewStage]
    let onSave: (InterviewStage, Date, StageLocation?) -> Void
    let onDelete: () -> Void
    let onSetStatus: (StageStatus) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStage: InterviewStage
    @State private var selectedDate: Date
    @State private var locationType: LocationType = .online
    @State private var address: String = ""
    @State private var sheetHeight: CGFloat = UIScreen.main.bounds.height * 0.4
    
    private var uniqueAvailableStages: [InterviewStage] {
        Array(Set(availableStages)).sorted { stage1, stage2 in
            let stageOrder: [InterviewStage] = [
                .resume,
                .written,
                .interview,
                .hrInterview,
                .offer
            ]
            let index1 = stageOrder.firstIndex(of: stage1) ?? 0
            let index2 = stageOrder.firstIndex(of: stage2) ?? 0
            return index1 < index2
        }
    }
    
    init(stage: InterviewStageItem,
         availableStages: [InterviewStage],
         onSave: @escaping (InterviewStage, Date, StageLocation?) -> Void,
         onDelete: @escaping () -> Void,
         onSetStatus: @escaping (StageStatus) -> Void) {
        self.stage = stage
        self.availableStages = availableStages
        self.onSave = onSave
        self.onDelete = onDelete
        self.onSetStatus = onSetStatus
        _selectedStage = State(initialValue: stage.stage)
        _selectedDate = State(initialValue: stage.date)
        _locationType = State(initialValue: stage.location?.type ?? .online)
        _address = State(initialValue: stage.location?.address ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    // 阶段选择
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(uniqueAvailableStages) { stage in
                                    Button {
                                        selectedStage = stage
                                    } label: {
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(selectedStage == stage ? stage.color : Color.gray.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                                .overlay {
                                                    Image(systemName: stage.icon)
                                                        .foregroundColor(selectedStage == stage ? .white : .gray)
                                                }
                                            Text(stage.rawValue)
                                                .font(.caption)
                                                .foregroundColor(selectedStage == stage ? stage.color : .gray)
                                        }
                                        .frame(width: 60)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("选择阶段")
                    }
                    
                    // 时间选择
                    Section {
                        TimeSelectionView(selectedDate: $selectedDate)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    
                    // 地点选择（仅面试和笔试阶段显示）
                    if [.interview, .written, .hrInterview].contains(selectedStage) {
                        Section {
                            Picker("方式", selection: $locationType) {
                                ForEach(LocationType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            
                            HStack {
                                Image(systemName: locationType == .online ? "link" : "mappin.and.ellipse")
                                    .foregroundColor(.blue)
                                TextField(locationType == .online ? 
                                         (selectedStage == .written ? "笔试链接" : "会议链接") :
                                         (selectedStage == .written ? "笔试地点" : "面试地点"),
                                         text: $address)
                            }
                        } header: {
                            Text(selectedStage == .written ? "笔试方式" : "面试方式")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // 底部按钮
                VStack(spacing: 16) {
                    Button {
                        var location: StageLocation?
                        if [.interview, .written, .hrInterview].contains(selectedStage) {
                            location = StageLocation(type: locationType, address: address)
                        }
                        onSave(selectedStage, selectedDate, location)
                        dismiss()
                    } label: {
                        Text("保存")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            onDelete()
                            dismiss()
                        } label: {
                            Text("删除")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Button {
                            onSetStatus(.passed)
                            dismiss()
                        } label: {
                            Text("通过")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Button {
                            onSetStatus(.failed)
                            dismiss()
                        } label: {
                            Text("未通过")
                                .font(.headline)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(16)
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("编辑阶段")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.7)])
        .presentationDragIndicator(.visible)
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
