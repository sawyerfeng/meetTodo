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
    @State private var isEditing = false
    @State private var cardStates: [ProcessType: Int] = [
        .application: 0,
        .interview: 0,
        .written: 0
    ]
    @State private var selectedItem: Item?
    
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
        
        // 投递公司统计
        let applications = filteredItems
        let totalApplications = applications.count
        let inProgressApplications = applications.filter { $0.status != .failed && $0.status != .offer }.count
        let completedApplications = applications.filter { $0.status == .offer }.count
        let applicationRate = totalApplications > 0 ? Int((Double(completedApplications) / Double(totalApplications)) * 100) : 0
        stats[.application] = [totalApplications, inProgressApplications, applicationRate]
        
        // 面试统计（包含所有轮次面试和HR面）
        var totalInterviews = 0
        var passedInterviews = 0
        
        for item in applications {
            // 计算普通面试轮次
            let normalInterviews = item.stages.filter { stageData in
                stageData.stage == InterviewStage.interview.rawValue
            }
            totalInterviews += normalInterviews.count
            passedInterviews += normalInterviews.filter { $0.status == StageStatus.passed.rawValue }.count
            
            // 计算HR面
            let hrInterviews = item.stages.filter { stageData in
                stageData.stage == InterviewStage.hrInterview.rawValue
            }
            totalInterviews += hrInterviews.count
            passedInterviews += hrInterviews.filter { $0.status == StageStatus.passed.rawValue }.count
        }
        
        let interviewRate = totalInterviews > 0 ? Int((Double(passedInterviews) / Double(totalInterviews)) * 100) : 0
        stats[.interview] = [totalInterviews, passedInterviews, interviewRate]
        
        // 笔试统计
        let written = applications.filter { item in
            item.stages.contains { stageData in
                stageData.stage == InterviewStage.written.rawValue
            }
        }
        let totalWritten = written.count
        let passedWritten = written.filter { item in
            item.stages.contains { stageData in
                stageData.stage == InterviewStage.written.rawValue && stageData.status == StageStatus.passed.rawValue
            }
        }.count
        let writtenRate = totalWritten > 0 ? Int((Double(passedWritten) / Double(totalWritten)) * 100) : 0
        stats[.written] = [totalWritten, passedWritten, writtenRate]
        
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
                                                            
                                                            Spacer()
                                                            
                                                            // 投递公司统计
                                                            let companies = items.filter { $0.recruitmentStage?.id == stage.id }
                                                            if !companies.isEmpty {
                                                                HStack(spacing: 2) {
                                                                    Image(systemName: "building.2")
                                                                        .foregroundColor(.red)
                                                                    Text("\(companies.count)")
                                                                        .font(.caption)
                                                                        .foregroundColor(.red)
                                                                }
                                                                .padding(.leading, 8)
                                                            }
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
                        ForEach(filteredItems.sorted { item1, item2 in
                            // 首先按置顶状态排序
                            if item1.isPinned != item2.isPinned {
                                return item1.isPinned
                            }
                            // 然后按时间戳排序
                            return item1.timestamp > item2.timestamp
                        }) { item in
                            CompanyRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = item
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
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onMove { from, to in
                            var items = filteredItems
                            items.move(fromOffsets: from, toOffset: to)
                            // 更新时间戳以保持顺序
                            for (index, item) in items.enumerated() {
                                item.timestamp = Date().addingTimeInterval(Double(-index))
                            }
                        }
                    }
                    .listStyle(.plain)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .opacity(0) // 隐藏编辑按钮但保持功能
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                CompanyDetailView(item: item)
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
                   currentState == 1 ? "面���通过" : "面试通过率"
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
    @State private var companyLogo: UIImage?
    @State private var isSearchingLogo = false
    
    // 预设的行业图标
    let industryIcons = [
        IconCategory(name: "互联网", icon: "network"),
        IconCategory(name: "金融", icon: "banknote"),
        IconCategory(name: "医疗", icon: "cross.case"),
        IconCategory(name: "教育", icon: "book"),
        IconCategory(name: "制造", icon: "gearshape.2"),
        IconCategory(name: "半导体", icon: "cpu"),
        IconCategory(name: "人工智能", icon: "brain.head.profile"),
        IconCategory(name: "游戏", icon: "gamecontroller"),
        IconCategory(name: "通用", icon: "building.2")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 公司名称输入
                TextField("公司名称", text: $companyName)
                    .font(.title3)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChange(of: companyName) { oldValue, newValue in
                        // 当公司名称改变且不为空时，自动搜索Logo
                        if !newValue.isEmpty {
                            searchCompanyLogo()
                        } else {
                            companyLogo = nil
                        }
                    }
                
                // 图标选择区域
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择图标")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // 图标列表
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Logo图标（如果有）
                            if isSearchingLogo {
                                ProgressView()
                                    .frame(width: 44, height: 44)
                            } else if let logo = companyLogo {
                                Button {
                                    companyIcon = ""  // 使用空字符串表示使用自定义Logo
                                } label: {
                                    Image(uiImage: logo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(companyIcon.isEmpty ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                            
                            // 预设图标列表
                            ForEach(industryIcons, id: \.icon) { category in
                                IconButton(
                                    icon: category.icon,
                                    isSelected: companyIcon == category.icon,
                                    onTap: { companyIcon = category.icon }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
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
            .presentationDetents([.height(300)]) 
            .presentationDragIndicator(.visible)
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
    
    private func searchCompanyLogo() {
        guard !companyName.isEmpty else { return }
        
        // 防止频繁搜索，添加延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 确保公司名称没有在延迟期间改变
            guard !companyName.isEmpty else { return }
            
            isSearchingLogo = true
            // 将公司名称转换为域名格式（简单处理）
            let companyDomain = companyName
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: " ", with: "")
            
            // 使用Clearbit Logo API
            let urlString = "https://logo.clearbit.com/\(companyDomain).com"
            
            guard let url = URL(string: urlString) else {
                isSearchingLogo = false
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    isSearchingLogo = false
                    
                    if let data = data, let image = UIImage(data: data) {
                        companyLogo = image
                        // 自动选择Logo作为图标
                        companyIcon = ""
                    }
                }
            }.resume()
        }
    }
    
    private func saveCompany() {
        let item = Item(
            companyName: companyName,
            companyIcon: companyIcon,
            processType: .application,
            currentStage: InterviewStage.resume.rawValue
        )
        
        // 如果选择了Logo，保存Logo数据
        if companyIcon.isEmpty, let logo = companyLogo {
            item.iconData = logo.pngData()
        }
        
        // 添加投递阶段
        let stageData = InterviewStageData(
            stage: InterviewStage.resume.rawValue,
            date: stageDate
        )
        item.stages.append(stageData)
        
        onSave(item)
    }
}

// 图标按钮组件
struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .gray)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                )
        }
    }
}

// 图标分类模型
struct IconCategory {
    let name: String
    let icon: String
}

// 公司
struct CompanyRow: View {
    let item: Item
    
    var formattedTime: String? {
        guard let nextDate = item.nextStageDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: nextDate)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                // 公司图标
                ZStack {
                    if let iconData = item.iconData,
                       let uiImage = UIImage(data: iconData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: item.companyIcon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                    }
                    
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .offset(x: 18, y: -18)
                    }
                }
                
                // 公司信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.companyName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(item.currentStage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let time = formattedTime {
                            Text(time)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    
                    Rectangle()
                        .fill(item.status.color)
                        .frame(width: geometry.size.width * CGFloat(item.status.percentage) / 100, height: 3)
                        .cornerRadius(1.5)
                }
            }
            .frame(height: 3)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(getStatusColor(for: item))
        .cornerRadius(12)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
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
