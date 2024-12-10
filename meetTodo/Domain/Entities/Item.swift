import Foundation
import SwiftData
import SwiftUI

@Model
final class Item {
    var id: String
    var timestamp: Date
    var companyName: String
    var companyIcon: String
    var iconData: Data?
    var currentStage: String
    var status: ProcessStatus
    var nextStageDate: Date?
    var isPinned: Bool
    @Transient
    var stages: [InterviewStageData] = []
    var calendarEventIdentifiers: [String]
    
    init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        companyName: String,
        companyIcon: String = "building.2",
        iconData: Data? = nil,
        currentStage: String = "未开始",
        status: ProcessStatus = .pending,
        nextStageDate: Date? = nil,
        isPinned: Bool = false,
        stages: [InterviewStageData] = [],
        calendarEventIdentifiers: [String] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.companyName = companyName
        self.companyIcon = companyIcon
        self.iconData = iconData
        self.currentStage = currentStage
        self.status = status
        self.nextStageDate = nextStageDate
        self.isPinned = isPinned
        self.stages = stages
        self.calendarEventIdentifiers = calendarEventIdentifiers
    }
    
    // 用于存储序列化后的 stages 数据
    @Attribute private var stagesData: Data?
    
    // 在数据加载时反序列化
    func didAwake() {
        if let data = stagesData {
            stages = (try? JSONDecoder().decode([InterviewStageData].self, from: data)) ?? []
        }
    }
    
    // 在数据保存时序列化
    func willSave() {
        stagesData = try? JSONEncoder().encode(stages)
    }
} 