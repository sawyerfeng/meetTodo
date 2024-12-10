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
    @State private var showingStageDetail = false
    @State private var stageForDetail: InterviewStageItem?
    @State private var showingIconPicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedIcon: String
    @State private var isEditingName = false
    @State private var editingName: String = ""
    
    init(item: Item) {
        self.item = item
        _selectedIcon = State(initialValue: item.companyIcon)
    }
    
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
    
    func getAvailableStagesForEdit(_ currentStage: InterviewStage) -> [InterviewStage] {
        let existingStages = Set(stages.map { $0.stage })
        let hasResume = existingStages.contains(.resume)
        let hasWritten = existingStages.contains(.written)
        let hasInterview = existingStages.contains(.interview)
        let hasOffer = existingStages.contains(.offer)
        
        return InterviewStage.allCases.filter { stage in
            // 当前阶段总是可选
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
    
    private func getStatusColor(for item: Item) -> Color {
        // 获取最新的阶段（按照阶段顺序和面试轮次排序）
        let sortedStages = item.stages.sorted { stage1, stage2 in
            let stageOrder: [InterviewStage] = [.resume, .written, .interview, .hrInterview, .offer]
            let index1 = stageOrder.firstIndex(of: InterviewStage(rawValue: stage1.stage) ?? .resume) ?? 0
            let index2 = stageOrder.firstIndex(of: InterviewStage(rawValue: stage2.stage) ?? .resume) ?? 0
            
            if index1 == index2 {
                if stage1.stage == InterviewStage.interview.rawValue {
                    return (stage1.interviewRound ?? 0) > (stage2.interviewRound ?? 0)
                }
                return stage1.date > stage2.date
            }
            return index1 > index2
        }
        
        guard let latestStage = sortedStages.first else {
            return Color.gray.opacity(0.1) // 没有阶段时显示灰色
        }
        
        // 检查是否有通过的Offer
        if latestStage.stage == InterviewStage.offer.rawValue &&
           latestStage.status == StageStatus.passed.rawValue {
            return Color.green.opacity(0.1) // Offer通过显示浅绿色
        }
        
        // 根据最新阶段的状态显示颜色
        switch latestStage.status {
        case StageStatus.failed.rawValue:
            return Color.red.opacity(0.1)
        case StageStatus.passed.rawValue:
            return Color.green.opacity(0.1)
        default:
            return Color.blue.opacity(0.1) // 进行中显示蓝色
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 固定在顶部的公司信息卡片
            VStack {
                // 公司信息卡片
                VStack(spacing: 8) {
                    ZStack {
                        if selectedImage != nil {
                            Image(uiImage: selectedImage!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                        } else if let iconData = item.iconData,
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
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 50))
                                        .foregroundColor(.blue)
                                }
                        }
                        
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .offset(x: 45, y: -45)
                        }
                    }
                    .onTapGesture {
                        showingIconPicker = true
                    }
                    
                    makeTextField(item.companyName, isEditing: isEditingName) { newName in
                        if newName != item.companyName {
                            item.companyName = newName
                            try? modelContext.save()
                        }
                        isEditingName = false
                    }
                    
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
                .padding()
                .background(getStatusColor(for: item))
                .cornerRadius(16)
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
            .zIndex(1)
            
            // 可滚动的阶段列表
            List {
                // 添加一个空的 Section 来为顶部卡片留出空间
                Section {
                    Color.clear
                        .frame(height: 280)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
                
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
                        if stage1.stage == .interview {
                            return (stage1.interviewRound ?? 0) > (stage2.interviewRound ?? 0)
                        }
                        return stage1.date > stage2.date
                    }
                    return index1 > index2
                }
                
                ForEach(Array(sortedStages.enumerated()), id: \.element.id) { index, stage in
                    StageRow(item: stage,
                            previousStage: index < sortedStages.count - 1 ? sortedStages[index + 1] : nil,
                            availableStages: getAvailableStagesForEdit(stage.stage),
                            onAction: { action in
                        handleStageAction(stage, action)
                    })
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            handleStageAction(stage, .setStatus(.failed))
                        } label: {
                            Label("未通过", systemImage: "xmark.circle")
                        }
                        .tint(.red)
                        
                        Button {
                            handleStageAction(stage, .setStatus(.passed))
                        } label: {
                            Label("通过", systemImage: "checkmark.circle")
                        }
                        .tint(.green)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                
                // 添加底部空间，避免加号按钮遮挡
                Color.clear
                    .frame(height: 100)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .zIndex(0)
            
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
            .zIndex(2)
        }
        .navigationDestination(isPresented: $showingStageDetail) {
            if let stage = stageForDetail {
                StageDetailView(item: stage, availableStages: availableStages) { action in
                    handleStageAction(stage, action)
                }
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
        .sheet(isPresented: $showingIconPicker) {
            CompanyIconPicker(selectedImage: $selectedImage, selectedIcon: $selectedIcon)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                // 压缩图数据
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    item.iconData = imageData
                    item.companyIcon = ""  // 清空系统图标
                    try? modelContext.save()
                }
            }
        }
        .onChange(of: selectedIcon) { _, newIcon in
            if newIcon != item.companyIcon {
                item.companyIcon = newIcon
                item.iconData = nil  // 清空自定义图片数据
                selectedImage = nil  // 清空选中的图片
                try? modelContext.save()
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
                
                // 如果新阶段要提醒，设置新的通知
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
    
    private func makeTextField(_ text: String, isEditing: Bool, onSubmit: @escaping (String) -> Void) -> some View {
        VStack {
            if isEditing {
                TextField("", text: .init(
                    get: { text },
                    set: { newValue in
                        if !newValue.isEmpty {
                            onSubmit(newValue)
                        }
                    }
                ))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .submitLabel(.done)
                .onAppear {
                    // 预加载输入法
                    let _ = UITextInputMode.activeInputModes
                    
                    // 确保输入法会话有效
                    if let clientClass = NSClassFromString("RTIInputSystemClient") {
                        let selector = NSSelectorFromString("currentTextInputSession")
                        let methodIMP = class_getClassMethod(clientClass, selector)
                        if methodIMP != nil {
                            typealias FunctionType = @convention(c) (AnyClass, Selector) -> Void
                            let method = unsafeBitCast(method_getImplementation(methodIMP!), to: FunctionType.self)
                            method(clientClass, selector)
                        }
                    }
                }
            } else {
                Button {
                    onSubmit(text)
                } label: {
                    Text(text)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
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
    @State private var showingMapActionSheet = false
    
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: item.date)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧图标和连接线
            VStack(spacing: 0) {
                if previousStage != nil && item.stage != .offer {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
                Circle()
                    .fill(item.stage.color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: item.stage.icon)
                            .foregroundColor(.white)
                    }
                if previousStage != nil && item.stage != .offer {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 40, height: 100)
            .padding(.horizontal, 16)
            
            // 连接线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 2)
                .frame(width: 20)
            
            // 右侧内容模块
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 状态图标
                    switch item.status {
                    case .passed:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .failed:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    case .pending:
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Text(formattedDateTime)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // 位置信息
                if let location = item.location {
                    Button {
                        showingMapActionSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(location.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(item.stage.color.opacity(0.1), lineWidth: 1)
            )
            
            Spacer(minLength: 16)
        }
        .padding(.vertical, 4)
        .confirmationDialog("选择地图应用", isPresented: $showingMapActionSheet) {
            if let location = item.location {
                Button("在高德地图中打开") {
                    openInAmap(address: location.address)
                }
                Button("在苹地图中打开") {
                    openInAppleMaps(address: location.address)
                }
                Button("取消", role: .cancel) { }
            }
        }
    }
    
    private func openInAmap(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // 尝试使用新版URL Scheme
        let urlString = "amap://poi?sourceApplication=meetTodo&keywords=\(encodedAddress)"
        let backupUrlString = "iosamap://path?sourceApplication=meetTodo&dname=\(encodedAddress)&dev=0&t=0"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url) { success in
                if !success, let backupUrl = URL(string: backupUrlString) {
                    UIApplication.shared.open(backupUrl) { success in
                        if !success {
                            // 如果都无法打开，跳转到App Store
                            if let appStoreURL = URL(string: "https://apps.apple.com/cn/app/id461703208") {
                                UIApplication.shared.open(appStoreURL)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func openInAppleMaps(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?q=\(encodedAddress)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
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
                    // 阶段择
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
                        Text("择阶段")
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

// ���改地点选择组件
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
                // 换型时保存当前地址并恢复之前的地址
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

struct StageDetailView: View {
    let item: InterviewStageItem
    let availableStages: [InterviewStage]
    let onAction: (StageRowAction) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showingEditor = false
    @State private var showingMapActionSheet = false
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: item.date)
    }
    
    var body: some View {
        List {
            // 阶段信息
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(item.stage.color)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: item.stage.icon)
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayName)
                            .font(.title2.bold())
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
            
            // 地点信息（如果有）
            if let location = item.location {
                Section {
                    HStack {
                        Image(systemName: location.type == .online ? "link" : "mappin.and.ellipse")
                            .foregroundColor(.blue)
                        Text(location.type == .online ? "在线" : "线下")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if location.type == .offline {
                            Button {
                                showingMapActionSheet = true
                            } label: {
                                Image(systemName: "map")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    if !location.address.isEmpty {
                        if location.type == .online {
                            Button {
                                if let url = URL(string: location.address) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text(location.address)
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Text(location.address)
                        }
                    }
                }
            }
            
            // 笔记（如果有）
            if !item.note.isEmpty {
                Section("笔记") {
                    Text(item.note)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    
                    Button {
                        onAction(.setStatus(.passed))
                        dismiss()
                    } label: {
                        Label("标记为通过", systemImage: "checkmark.circle")
                    }
                    
                    Button {
                        onAction(.setStatus(.failed))
                        dismiss()
                    } label: {
                        Label("标记为未通过", systemImage: "xmark.circle")
                    }
                    
                    Button(role: .destructive) {
                        onAction(.delete)
                        dismiss()
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            StageEditorView(
                stage: item,
                availableStages: availableStages,
                onSave: { newStage, newDate, location in
                    onAction(.update(newStage, newDate, location))
                    dismiss()
                },
                onDelete: {
                    onAction(.delete)
                    dismiss()
                },
                onSetStatus: { status in
                    onAction(.setStatus(status))
                    dismiss()
                }
            )
        }
        .confirmationDialog("选择地图应用", isPresented: $showingMapActionSheet) {
            if let location = item.location {
                Button("在高德地图中打开") {
                    openInAmap(address: location.address)
                }
                Button("在���地图中打开") {
                    openInAppleMaps(address: location.address)
                }
                Button("取消", role: .cancel) { }
            }
        }
    }
    
    private func openInAmap(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // 尝试使用新版URL Scheme
        let urlString = "amap://poi?sourceApplication=meetTodo&keywords=\(encodedAddress)"
        let backupUrlString = "iosamap://path?sourceApplication=meetTodo&dname=\(encodedAddress)&dev=0&t=0"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url) { success in
                if !success, let backupUrl = URL(string: backupUrlString) {
                    UIApplication.shared.open(backupUrl) { success in
                        if !success {
                            // 如果都无法打开，跳转到App Store
                            if let appStoreURL = URL(string: "https://apps.apple.com/cn/app/id461703208") {
                                UIApplication.shared.open(appStoreURL)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func openInAppleMaps(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?q=\(encodedAddress)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

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
