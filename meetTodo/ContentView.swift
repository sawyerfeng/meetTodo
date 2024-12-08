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
    @Query(sort: [
        SortDescriptor<Item>(\.timestamp, order: .reverse)
    ], animation: .default) private var items: [Item]
    
    @State private var showingAddCompany = false
    @State private var cardStates: [ProcessType: Int] = [
        .application: 0,
        .interview: 0,
        .written: 0
    ]
    
    // 获取各种统计数据
    var statistics: [ProcessType: [Int]] {
        [
            .application: getApplicationStats(),
            .interview: getInterviewStats(),
            .written: getWrittenStats()
        ]
    }
    
    private func getApplicationStats() -> [Int] {
        let total = items.filter { $0.processType == .application }.count
        let offers = items.filter { $0.status == .offer }.count
        let rate = total > 0 ? Int((Double(offers) / Double(total) * 100).rounded()) : 0
        return [total, offers, rate]
    }
    
    private func getInterviewStats() -> [Int] {
        let total = items.filter { item in
            item.stages.contains { $0.stage == InterviewStage.interview.rawValue }
        }.count
        
        let passed = items.filter { item in
            item.stages.contains { stageData in
                stageData.stage == InterviewStage.interview.rawValue &&
                stageData.status == StageStatus.passed.rawValue
            }
        }.count
        
        let rate = total > 0 ? Int((Double(passed) / Double(total) * 100).rounded()) : 0
        return [total, passed, rate]
    }
    
    private func getWrittenStats() -> [Int] {
        let total = items.filter { item in
            item.stages.contains { $0.stage == InterviewStage.written.rawValue }
        }.count
        
        let passed = items.filter { item in
            item.stages.contains { stageData in
                stageData.stage == InterviewStage.written.rawValue &&
                stageData.status == StageStatus.passed.rawValue
            }
        }.count
        
        let rate = total > 0 ? Int((Double(passed) / Double(total) * 100).rounded()) : 0
        return [total, passed, rate]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
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
                        ForEach(items) { item in
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
                            showingAddCompany = true
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
            .sheet(isPresented: $showingAddCompany) {
                AddCompanyView { newItem in
                    modelContext.insert(newItem)
                    showingAddCompany = false
                }
            }
        }
        .task {
            // 预加载数据
            _ = items.count
        }
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
            .presentationDetents([.height(250)]) // 设置固定高度
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

// 公司行
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

// 图标选择器视图
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
