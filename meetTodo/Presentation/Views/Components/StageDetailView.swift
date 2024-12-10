import SwiftUI

struct StageDetailView: View {
    let item: InterviewStageItem
    let availableStages: [InterviewStage]
    let onAction: (StageRowAction) -> Void
    
    @State private var selectedStage: InterviewStage
    @State private var selectedDate: Date
    @State private var note: String
    @State private var locationType: LocationType = .online
    @State private var address: String = ""
    @State private var showingDeleteAlert = false
    
    init(item: InterviewStageItem, availableStages: [InterviewStage], onAction: @escaping (StageRowAction) -> Void) {
        self.item = item
        self.availableStages = availableStages
        self.onAction = onAction
        
        _selectedStage = State(initialValue: item.stage)
        _selectedDate = State(initialValue: item.date)
        _note = State(initialValue: item.note)
        
        if let location = item.location {
            _locationType = State(initialValue: location.type)
            _address = State(initialValue: location.address)
        }
    }
    
    var body: some View {
        Form {
            Section {
                Picker("阶段", selection: $selectedStage) {
                    ForEach(availableStages, id: \.self) { stage in
                        Text(stage.rawValue).tag(stage)
                    }
                }
                
                DatePicker("时间", selection: $selectedDate)
            }
            
            Section {
                Picker("地点", selection: $locationType) {
                    ForEach(LocationType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                TextField(locationType == .online ? 
                         (selectedStage == .written ? "笔试链接" : "会议链接") :
                         (selectedStage == .written ? "笔试地点" : "面试地点"),
                         text: $address)
            }
            
            Section("备注") {
                TextEditor(text: $note)
                    .frame(height: 100)
            }
            
            Section {
                Button("保存") {
                    let location = address.isEmpty ? nil : StageLocation(type: locationType, address: address)
                    onAction(.update(selectedStage, selectedDate, location))
                }
                
                Button("删除", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
        }
        .navigationTitle(item.stage.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                onAction(.delete)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除这个阶段吗？")
        }
    }
}

#Preview {
    NavigationStack {
        StageDetailView(
            item: InterviewStageItem(
                stage: .interview,
                interviewRound: 1,
                date: Date(),
                note: "这是一个测试笔记",
                location: StageLocation(type: .offline, address: "北京市朝阳区xxx街道")
            ),
            availableStages: InterviewStage.allCases,
            onAction: { _ in }
        )
    }
}