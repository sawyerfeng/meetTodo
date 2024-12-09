import Foundation

/// 面试阶段数据
struct InterviewStageData: Codable {
    /// 唯一标识符
    let id: String
    
    /// 阶段类型
    var stage: String
    
    /// 面试轮次（可选）
    var interviewRound: Int?
    
    /// 阶段日期
    var date: Date
    
    /// 备注
    var note: String
    
    /// 状态
    var status: String
    
    /// 地点信息（可选）
    var location: StageLocation?
    
    /// 初始化方法
    /// - Parameters:
    ///   - id: 唯一标识符
    ///   - stage: 阶段类型
    ///   - interviewRound: 面试轮次
    ///   - date: 阶段日期
    ///   - note: 备注
    ///   - status: 状态
    ///   - location: 地点信息
    init(id: String = UUID().uuidString,
         stage: String,
         interviewRound: Int? = nil,
         date: Date = Date(),
         note: String = "",
         status: String = "pending",
         location: StageLocation? = nil) {
        self.id = id
        self.stage = stage
        self.interviewRound = interviewRound
        self.date = date
        self.note = note
        self.status = status
        self.location = location
    }
} 