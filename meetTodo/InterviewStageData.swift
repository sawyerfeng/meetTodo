import Foundation

enum LocationType: String, Codable, CaseIterable {
    case online = "线上"
    case offline = "线下"
}

struct StageLocation: Codable, Equatable {
    var type: LocationType
    var address: String // 线下地址或线上链接
    
    static func == (lhs: StageLocation, rhs: StageLocation) -> Bool {
        return lhs.type == rhs.type && lhs.address == rhs.address
    }
}

struct InterviewStageData: Codable {
    let id: String
    var stage: String
    var interviewRound: Int?
    var date: Date
    var note: String
    var status: String
    var location: StageLocation?
    
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
