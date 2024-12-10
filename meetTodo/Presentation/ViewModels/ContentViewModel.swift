import SwiftUI
import SwiftData

@MainActor
class ContentViewModel: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var showingAddSheet = false
    @Published var showingStageSheet = false
    @Published var editingStage: RecruitmentStage?
    @Published var showingDeleteAlert = false
    @Published var stageToDelete: RecruitmentStage?
    @Published var showingAddStageInput = false
    @Published var newStageName = ""
    @Published var editingText = ""
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var isEditing = false
    @Published var cardStates: [ProcessType: Int] = [
        .application: 0,
        .interview: 0,
        .written: 0
    ]
    @Published var selectedItem: Item?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addNewStage() {
        let trimmedName = newStageName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.count > 10 {
            showError("阶段名称不能超过10个字符")
            return
        }
        
        if trimmedName.isEmpty {
            showError("阶段名称不能为空")
            return
        }
        
        let newStage = RecruitmentStage(name: trimmedName)
        modelContext.insert(newStage)
        try? modelContext.save()
        
        newStageName = ""
        showingAddStageInput = false
    }
    
    func deleteStage(_ stage: RecruitmentStage) {
        modelContext.delete(stage)
        try? modelContext.save()
    }
    
    func updateStage(_ stage: RecruitmentStage, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.count > 10 {
            showError("阶段名称不能超过10个字符")
            return
        }
        
        if trimmedName.isEmpty {
            showError("阶段名称不能为空")
            return
        }
        
        stage.name = trimmedName
        try? modelContext.save()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func updateCardStates(items: [Item]) {
        var newStates: [ProcessType: Int] = [
            .application: 0,
            .interview: 0,
            .written: 0
        ]
        
        for item in items {
            switch item.status {
            case .resume:
                newStates[.application, default: 0] += 1
            case .written:
                newStates[.written, default: 0] += 1
            case .interview1, .interview2, .interview3, .hrInterview:
                newStates[.interview, default: 0] += 1
            default:
                break
            }
        }
        
        cardStates = newStates
    }
} 