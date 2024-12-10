//
//  ContentView.swift
//  meetTodo
//
//  Created by pygmalion on 2024/12/8.
//

import SwiftUI
import SwiftData

// 添加 DateFormatter 扩展
extension DateFormatter {
    static let customFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Item> { _ in true },
        sort: [.init(\Item.timestamp, order: .reverse)]
    ) private var items: [Item]
    @Query private var stages: [RecruitmentStage]
    @State private var showingAddSheet = false
    @State private var showingStageSheet = false
    @State private var editingStage: RecruitmentStage?
    @State private var showingDeleteAlert = false
    @State private var stageToDelete: RecruitmentStage?
    @State private var showingAddStageInput = false
    @State private var newStageName = ""
    @State private var editingText = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var cardStates: [ProcessType: Int] = [
        .application: 0,
        .interview: 0,
        .written: 0
    ]
    
    private func addNewStage() {
        let trimmedName = newStageName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查名称长度
        if trimmedName.count > 10 {
            errorMessage = "阶段名称不能超过10个字"
            withAnimation {
                showingError = true
            }
            return
        }
        
        // 检查是否为空
        if trimmedName.isEmpty {
            errorMessage = "请输入阶段名称"
            withAnimation {
                showingError = true
            }
            return
        }
        
        // 检查重名
        if stages.contains(where: { $0.name == trimmedName }) {
            errorMessage = "已存在相同名称的阶段"
            withAnimation {
                showingError = true
            }
            return
        }
        
        let newStage = RecruitmentStage(name: trimmedName, isSelected: false)
        modelContext.insert(newStage)
        newStageName = ""
        showingError = false
        withAnimation {
            showingAddStageInput = false
        }
    }
    
    var filteredItems: [Item] {
        if let selectedStage = stages.first(where: { $0.isSelected }) {
            return items.filter { $0.recruitmentStage?.id == selectedStage.id }
        }
        return items
    }
    
    var currentStageName: String {
        stages.first(where: { $0.isSelected })?.name ?? "选择阶段"
    }
    
    var statistics: [ProcessType: [Int]] {
        var stats: [ProcessType: [Int]] = [:]
        for type in [ProcessType.application, .interview, .written] {
            let typeItems = filteredItems.filter { $0.processType == type }
            let total = typeItems.count
            let inProgress = typeItems.filter { $0.status != ProcessStatus.failed && $0.status != ProcessStatus.offer }.count
            let completed = typeItems.filter { $0.status == ProcessStatus.offer }.count
            let rate = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
            stats[type] = [total, inProgress, rate]
        }
        return stats
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    // 阶段选择器按钮
                    HStack {
                        Spacer()
                        Button {
                            showingStageSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(currentStageName)
                                    .font(.headline)
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                        }
                        .sheet(isPresented: $showingStageSheet) {
                            NavigationStack {
                                VStack(spacing: 0) {
                                    if showingAddStageInput {
                                        VStack(spacing: 8) {
                                            HStack {
                                                TextField("输入新阶段名称", text: $newStageName)
                                                    .textFieldStyle(.roundedBorder)
                                                    .submitLabel(.done)
                                                    .onSubmit(addNewStage)
                                                
                                                Button(action: addNewStage) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.title2)
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .padding(.horizontal)
                                            .padding(.top)
                                            
                                            if showingError {
                                                Text(errorMessage)
                                                    .foregroundColor(.red)
                                                    .font(.caption)
                                            }
                                        }
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                        
                                        Divider()
                                            .padding(.vertical)
                                    }
                                    
                                    List {
                                        ForEach(stages) { stage in
                                            HStack {
                                                if editingStage?.id == stage.id {
                                                    TextField("阶段名称", text: $editingText)
                                                        .textFieldStyle(.roundedBorder)
                                                        .submitLabel(.done)
                                                        .onSubmit {
                                                            let trimmedName = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
                                                            if !trimmedName.isEmpty && trimmedName.count <= 10 &&
                                                                !stages.contains(where: { $0.id != stage.id && $0.name == trimmedName }) {
                                                                stage.name = trimmedName
                                                                editingStage = nil
                                                                editingText = ""
                                                            }
                                                        }
                                                    
                                                    Button {
                                                        editingStage = nil
                                                        editingText = ""
                                                    } label: {
                                                        Text("完成")
                                                            .foregroundColor(.blue)
                                                    }
                                                } else {
                                                    Button {
                                                        selectStage(stage)
                                                        showingStageSheet = false
                                                    } label: {
                                                        HStack {
                                                            Image(systemName: stage.isSelected ? "checkmark.circle.fill" : "circle")
                                                                .foregroundColor(stage.isSelected ? .blue : .gray)
                                                            Text(stage.name)
                                                                .foregroundColor(.primary)
                                                        }
                                                    }
                                                }
                                            }
                                            .swipeActions(edge: .trailing) {
                                                if stages.count > 1 {
                                                    Button(role: .destructive) {
                                                        stageToDelete = stage
                                                        showingDeleteAlert = true
                                                    } label: {
                                                        Label("删除", systemImage: "trash")
                                                    }
                                                    
                                                    Button {
                                                        editingStage = stage
                                                        editingText = stage.name
                                                    } label: {
                                                        Label("编辑", systemImage: "pencil")
                                                    }
                                                    .tint(.orange)
                                                }
                                            }
                                        }
                                    }
                                }
                                .navigationTitle("管理阶段")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button {
                                            withAnimation {
                                                showingAddStageInput.toggle()
                                                if !showingAddStageInput {
                                                    newStageName = ""
                                                    showingError = false
                                                }
                                            }
                                        } label: {
                                            Text(showingAddStageInput ? "完成" : "添加")
                                        }
                                    }
                                }
                                .alert("确认删除", isPresented: $showingDeleteAlert) {
                                    Button("取消", role: .cancel) {}
                                    Button("删除", role: .destructive) {
                                        if let stage = stageToDelete {
                                            deleteStage(stage)
                                        }
                                    }
                                } message: {
                                    if let stage = stageToDelete {
                                        Text("确定要删除「\(stage.name)」阶段吗？该阶段下的所有公司也会被删除。")
                                    }
                                }
                            }
                            .presentationDetents([.height(400)])
                            .presentationDragIndicator(.visible)
                        }
                        .padding(.trailing)
                    }
                    
                    // 看板
                    HStack(spacing: 12) {
                        ProcessTypeCard(type: .application,
                                      stats: statistics[.application] ?? [0, 0, 0],
                                      currentState: cardStates[.application] ?? 0) {
                            withAnimation {
                                cardStates[.application] = ((cardStates[.application] ?? 0) + 1) % 3
                            }
                        }
                        ProcessTypeCard(type: .interview,
                                      stats: statistics[.interview] ?? [0, 0, 0],
                                      currentState: cardStates[.interview] ?? 0) {
                            withAnimation {
                                cardStates[.interview] = ((cardStates[.interview] ?? 0) + 1) % 3
                            }
                        }
                        ProcessTypeCard(type: .written,
                                      stats: statistics[.written] ?? [0, 0, 0],
                                      currentState: cardStates[.written] ?? 0) {
                            withAnimation {
                                cardStates[.written] = ((cardStates[.written] ?? 0) + 1) % 3
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 公司列表
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                CompanyDetailView(item: item)
                            } label: {
                                CompanyRow(item: item)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(item)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation {
                                        item.isPinned.toggle()
                                    }
                                } label: {
                                    Label(item.isPinned ? "取消置顶" : "置顶",
                                          systemImage: item.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
                
                // 浮动添加按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddSheet = true
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
            .navigationTitle("面试进度")
            .sheet(isPresented: $showingAddSheet) {
                AddCompanyView { newItem in
                    if let selectedStage = stages.first(where: { $0.isSelected }) {
                        newItem.recruitmentStage = selectedStage
                    }
                    modelContext.insert(newItem)
                    showingAddSheet = false
                }
            }
        }
        .task {
            if stages.isEmpty {
                RecruitmentStage.createDefaultStage(context: modelContext)
            }
        }
    }
    
    private func selectStage(_ selectedStage: RecruitmentStage) {
        for stage in stages {
            stage.isSelected = (stage.id == selectedStage.id)
        }
    }
    
    private func deleteStage(_ stage: RecruitmentStage) {
        if stages.count <= 1 { return }
        
        // 如果删除的是当前选中的阶段，选中另一个阶段
        if stage.isSelected, let newSelectedStage = stages.first(where: { $0.id != stage.id }) {
            newSelectedStage.isSelected = true
        }
        
        // 删除关联的公司
        items.filter { $0.recruitmentStage?.id == stage.id }.forEach { item in
            modelContext.delete(item)
        }
        
        modelContext.delete(stage)
    }
}

// 修改后的 ProcessTypeCard
struct ProcessTypeCard: View {
    let type: ProcessType
    let stats: [Int] // [总数, 通过数, 通过率]
    let currentState: Int
    let onTap: () -> Void
    
    var title: String {
        switch type {
        case .application:
            return currentState == 0 ? "投递公司" :
                   currentState == 1 ? "Offer" : "录用率"
        case .interview:
            return currentState == 0 ? "面试" :
                   currentState == 1 ? "面试通过" : "面试通过率"
        case .written:
            return currentState == 0 ? "笔试" :
                   currentState == 1 ? "笔试通过" : "笔试通过率"
        }
    }
    
    var displayValue: String {
        if currentState == 2 {
            return "\(stats[2])%"
        }
        return "\(stats[currentState])"
    }
    
    var color: Color {
        switch type {
        case .application: return .red
        case .interview: return .blue
        case .written: return .orange
        }
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(displayValue)
                    .font(.title.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

// 修改 AddCompanyView
struct AddCompanyView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Item) -> Void
    
    @State private var companyName = ""
    @State private var companyIcon = "building.2"
    @State private var stageDate = Date()
    
    // 预设的常用公司图标
    let commonIcons = [
        "building.2",
        "building.columns",
        "globe.asia.australia",
        "network",
        "server.rack",
        "cpu"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 公司名称输入
                TextField("公司名称", text: $companyName)
                    .font(.title3)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // 图标选择
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(commonIcons, id: \.self) { icon in
                            Button {
                                companyIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(icon == companyIcon ? .blue : .gray)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(icon == companyIcon ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 投递日期
                DatePicker("投递日期", 
                          selection: $stageDate,
                          displayedComponents: [.date, .hourAndMinute])
                    .padding(.horizontal)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                
                Divider()
                    .padding(.vertical, 10)
            }
            .padding(.top, 20)
            .presentationDetents([.height(250)]) // 设置定度
            .presentationDragIndicator(.visible) // 显示拖动指示器
            .navigationTitle("添加公司")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        saveCompany()
                    }
                    .disabled(companyName.isEmpty)
                }
            }
        }
    }
    
    private func saveCompany() {
        let item = Item(
            companyName: companyName,
            companyIcon: companyIcon,
            processType: .application,
            currentStage: InterviewStage.resume.rawValue
        )
        
        // 添加投递阶段
        let stageData = InterviewStageData(
            stage: InterviewStage.resume.rawValue,
            date: stageDate
        )
        item.stages.append(stageData)
        
        onSave(item)
    }
}

// 公司
struct CompanyRow: View {
    let item: Item
    
    var progressColor: Color {
        item.status.color
    }
    
    var formattedDate: String {
        guard let date = item.nextStageDate else { return "" }
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: date)
    }
    
    var formattedDay: String {
        guard let date = item.nextStageDate else { return "" }
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy年MM月dd日"
        return dayFormatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 公司图标
            ZStack {
                Image(systemName: item.companyIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .offset(x: 15, y: -15)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.companyName)
                    .font(.headline)
                HStack {
                    Text(item.currentStage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if item.nextStageDate != nil {
                        Text(formattedDay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 时间显示
            if let _ = item.nextStageDate {
                Text(formattedDate)
                    .font(.title3.bold())
                    .foregroundColor(.blue)
                    .frame(minWidth: 60)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(progressColor.opacity(0.15))
                        .frame(width: geometry.size.width * CGFloat(item.status.percentage) / 100)
                    Rectangle()
                        .fill(Color.gray.opacity(0.05))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// 图标选择视图
struct IconPickerView: View {
    @Binding var selectedIcon: String
    let icons: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(icons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text(icon)
                            .foregroundColor(.primary)
                        Spacer()
                        if icon == selectedIcon {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
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
    }
}

struct AddStageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var stageName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("阶段名称（如：秋招、春招）", text: $stageName)
            }
            .navigationTitle("添加阶段")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("添加") {
                    let newStage = RecruitmentStage(name: stageName, isSelected: false)
                    modelContext.insert(newStage)
                    dismiss()
                }
                .disabled(stageName.isEmpty)
            )
        }
    }
}

struct EditStageView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var stage: RecruitmentStage
    @State private var stageName: String
    
    init(stage: RecruitmentStage) {
        self.stage = stage
        self._stageName = State(initialValue: stage.name)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("阶段名称", text: $stageName)
            }
            .navigationTitle("编辑阶段")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    stage.name = stageName
                    dismiss()
                }
                .disabled(stageName.isEmpty)
            )
        }
    }
}

struct StageOptionsMenu: View {
    let stages: [RecruitmentStage]
    let onStageSelect: (RecruitmentStage) -> Void
    let onStageEdit: (RecruitmentStage) -> Void
    let onStageDelete: (RecruitmentStage) -> Void
    let onAddNew: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(stages) { stage in
                HStack {
                    Button {
                        onStageSelect(stage)
                    } label: {
                        HStack {
                            Text(stage.name)
                                .foregroundColor(stage.isSelected ? .blue : .primary)
                            Spacer()
                            if stage.isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    
                    if stages.count > 1 {
                        Menu {
                            Button {
                                onStageEdit(stage)
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                onStageDelete(stage)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            Divider()
                .padding(.horizontal, 8)
            
            Button {
                onAddNew()
            } label: {
                HStack {
                    Text("添加新阶段")
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .padding(.vertical, 4)
        .frame(width: 180)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    
    let item1 = Item(companyName: "阿里巴巴",
                    companyIcon: "building.2.fill",
                    processType: .application,
                    currentStage: "投递",
                    status: .resume,
                    nextStageDate: Date().addingTimeInterval(86400),
                    isPinned: true)
    
    container.mainContext.insert(item1)
    
    return ContentView()
        .modelContainer(container)
}
