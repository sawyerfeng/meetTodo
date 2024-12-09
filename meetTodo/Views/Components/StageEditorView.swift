import SwiftUI

struct StageEditorView: View {
    let stage: InterviewStageItem
    let availableStages: [InterviewStage]
    let onSave: (InterviewStage, Date, StageLocation?) -> Void
    let onDelete: () -> Void
    let onSetStatus: (StageStatus) -> Void
    @Environment(\.dismiss) private var dismiss
    
    // 将所有状态变量标记为 private(set)
    @State private(set) var selectedStage: InterviewStage
    @State private(set) var selectedDate: Date
    @State private(set) var locationType: LocationType
    @State private(set) var address: String
    @State private(set) var currentStatus: StageStatus
    @State private var showLocationSection: Bool
    
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
        
        // 初始化所有状态
        _selectedStage = State(initialValue: stage.stage)
        _selectedDate = State(initialValue: stage.date)
        _locationType = State(initialValue: stage.location?.type ?? .online)
        _address = State(initialValue: stage.location?.address ?? "")
        _currentStatus = State(initialValue: stage.status)
        _showLocationSection = State(initialValue: [.interview, .written, .hrInterview].contains(stage.stage))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 阶段选择
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(uniqueAvailableStages) { stage in
                                Button {
                                    withAnimation {
                                        selectedStage = stage
                                        showLocationSection = [.interview, .written, .hrInterview].contains(stage)
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
                    DatePicker("时间", selection: $selectedDate)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
                
                // 地点选择（仅面试和笔试阶段显示）
                if showLocationSection {
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
                    }
                }
                
                // 状态选择
                Section {
                    HStack {
                        Text("当前状态")
                        Spacer()
                        Menu {
                            ForEach([StageStatus.pending, .passed, .failed], id: \.self) { status in
                                Button {
                                    currentStatus = status
                                    onSetStatus(status)
                                } label: {
                                    Label(status.rawValue, systemImage: status == .pending ? "clock" :
                                                                       status == .passed ? "checkmark.circle" : "xmark.circle")
                                }
                            }
                        } label: {
                            Text(currentStatus.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 删除按钮
                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除阶段")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑阶段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let location: StageLocation?
                        if showLocationSection && !address.isEmpty {
                            location = StageLocation(type: locationType, address: address)
                        } else {
                            location = nil
                        }
                        onSave(selectedStage, selectedDate, location)
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
} 