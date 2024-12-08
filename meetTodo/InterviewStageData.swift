import Foundation

struct InterviewStageData: Codable {
    let id: String
    var stage: String
    var interviewRound: Int?
    var date: Date
    var note: String
    var status: String
    
    init(id: String = UUID().uuidString,
         stage: String,
         interviewRound: Int? = nil,
         date: Date = Date(),
         note: String = "",
         status: String = "pending") {
        self.id = id
        self.stage = stage
        self.interviewRound = interviewRound
        self.date = date
        self.note = note
        self.status = status
    }
} 