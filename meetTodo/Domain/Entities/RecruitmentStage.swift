import SwiftUI
import SwiftData

@Model
class RecruitmentStage {
    var name: String
    var createdAt: Date
    var isSelected: Bool
    
    init(name: String, isSelected: Bool = false) {
        self.name = name
        self.createdAt = Date()
        self.isSelected = isSelected
    }
    
    static func createDefaultStage(context: ModelContext) {
        let defaultStage = RecruitmentStage(name: "秋招", isSelected: true)
        context.insert(defaultStage)
    }
} 