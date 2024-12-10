import SwiftUI
import SwiftData

@MainActor
class CompanyDetailViewModel: ObservableObject {
    let modelContext: ModelContext
    let item: Item
    
    @Published var stages: [InterviewStageData] = []
    @Published var showingStageSelector = false
    @Published var showingNoteEditor = false
    @Published var selectedStage: InterviewStageData?
    @Published var showingFailureAlert = false
    @Published var showingStageDetail = false
    @Published var stageForDetail: InterviewStageData?
    @Published var showingIconPicker = false
    @Published var selectedImage: UIImage?
    @Published var selectedIcon: String
    @Published var isEditingName = false
    @Published var editingName: String = ""
    @Published var selectedStageForAdd: InterviewStage?
    
    init(modelContext: ModelContext, item: Item) {
        self.modelContext = modelContext
        self.item = item
        self._selectedIcon = Published(initialValue: item.companyIcon)
        loadStages()
    }
    
    func loadStages() {
        stages = item.stages
    }
    
    func saveStages(_ newStages: [InterviewStageData]) {
        stages = newStages
        item.stages = newStages
        try? modelContext.save()
    }
    
    func addStage(_ stageData: InterviewStageData) {
        stages.append(stageData)
        item.stages = stages
        try? modelContext.save()
    }
    
    func updateStageNote(_ stage: InterviewStageData, newNote: String) {
        if let index = stages.firstIndex(where: { $0.id == stage.id }) {
            stages[index].note = newNote
            item.stages = stages
            try? modelContext.save()
        }
    }
    
    func deleteStage(_ stage: InterviewStageData) {
        stages.removeAll { $0.id == stage.id }
        item.stages = stages
        try? modelContext.save()
    }
    
    func getNextInterviewRound(for stage: InterviewStage) -> Int? {
        if stage == .interview {
            let existingRounds = stages
                .filter { $0.stage == InterviewStage.interview.rawValue }
                .compactMap { $0.interviewRound }
            
            if let maxRound = existingRounds.max() {
                return maxRound + 1
            }
            return 1
        }
        return nil
    }
    
    func getAvailableStagesForAdd() -> [InterviewStage] {
        let usedStages = Set(stages.map { $0.stage })
        return InterviewStage.allCases.filter { stage in
            !usedStages.contains(stage.rawValue) ||
            stage == .interview
        }
    }
    
    func getAvailableStagesForEdit(_ currentStage: String) -> [InterviewStage] {
        InterviewStage.allCases
    }
    
    func handleStageAction(_ stage: InterviewStageData, _ action: StageRowAction) {
        switch action {
        case .setStatus(let status):
            if let index = stages.firstIndex(where: { $0.id == stage.id }) {
                stages[index].status = status.rawValue
                if status == .failed {
                    showingFailureAlert = true
                }
            }
        case .editNote:
            selectedStage = stage
        case .update(let newStage, let date, let location):
            if let index = stages.firstIndex(where: { $0.id == stage.id }) {
                stages[index].stage = newStage.rawValue
                stages[index].date = date
                stages[index].location = location
            }
        case .delete:
            stages.removeAll { $0.id == stage.id }
        }
        
        item.stages = stages
        try? modelContext.save()
    }
    
    func getStatusColor(for item: Item) -> Color {
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
            return Color.gray.opacity(0.1)
        }
        
        if latestStage.stage == InterviewStage.offer.rawValue &&
           latestStage.status == StageStatus.passed.rawValue {
            return Color.green.opacity(0.1)
        }
        
        switch latestStage.status {
        case StageStatus.failed.rawValue:
            return Color.red.opacity(0.1)
        case StageStatus.passed.rawValue:
            return Color.green.opacity(0.1)
        default:
            return Color.blue.opacity(0.1)
        }
    }
} 