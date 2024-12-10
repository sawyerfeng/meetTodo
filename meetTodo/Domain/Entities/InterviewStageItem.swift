import Foundation

struct InterviewStageItem: Identifiable, Equatable {
    let id: UUID
    var stage: InterviewStage
    var interviewRound: Int?
    var date: Date
    var note: String
    var status: StageStatus
    var location: StageLocation?
    
    init(
        id: UUID = UUID(),
        stage: InterviewStage,
        interviewRound: Int? = nil,
        date: Date = Date(),
        note: String = "",
        status: StageStatus = .pending,
        location: StageLocation? = nil
    ) {
        self.id = id
        self.stage = stage
        self.interviewRound = interviewRound
        self.date = date
        self.note = note
        self.status = status
        self.location = location
    }
    
    static func == (lhs: InterviewStageItem, rhs: InterviewStageItem) -> Bool {
        return lhs.id == rhs.id &&
            lhs.stage == rhs.stage &&
            lhs.interviewRound == rhs.interviewRound &&
            lhs.date == rhs.date &&
            lhs.note == rhs.note &&
            lhs.status == rhs.status &&
            lhs.location == rhs.location
    }
} 