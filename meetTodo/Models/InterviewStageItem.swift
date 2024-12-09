import Foundation

/// 面试阶段项
public struct InterviewStageItem: Identifiable, Equatable {
    /// 唯一标识符
    public var id: UUID
    
    /// 阶段类型
    public var stage: InterviewStage
    
    /// 面试轮次（可选）
    public var interviewRound: Int?
    
    /// 阶段日期
    public var date: Date
    
    /// 备注
    public var note: String
    
    /// 状态
    public var status: StageStatus
    
    /// 地点信息（可选）
    public var location: StageLocation?
    
    /// 显示名称
    public var displayName: String {
        if stage == .interview, let round = interviewRound {
            return "第\(round)面"
        }
        return stage.rawValue
    }
    
    /// 初始化方法
    /// - Parameters:
    ///   - id: 唯一标识符
    ///   - stage: 阶段类型
    ///   - interviewRound: 面试轮次
    ///   - date: 阶段日期
    ///   - note: 备注
    ///   - status: 状态
    ///   - location: 地点信息
    public init(id: UUID = UUID(),
         stage: InterviewStage,
         interviewRound: Int? = nil,
         date: Date = Date(),
         note: String = "",
         status: StageStatus = .pending,
         location: StageLocation? = nil) {
        self.id = id
        self.stage = stage
        self.interviewRound = interviewRound
        self.date = date
        self.note = note
        self.status = status
        self.location = location
    }
    
    /// 相等性比较
    public static func == (lhs: InterviewStageItem, rhs: InterviewStageItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.stage == rhs.stage &&
        lhs.interviewRound == rhs.interviewRound &&
        lhs.date == rhs.date &&
        lhs.note == rhs.note &&
        lhs.status == rhs.status &&
        lhs.location == rhs.location
    }
} 