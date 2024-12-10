//
//  Item.swift
//  meetTodo
//
//  Created by pygmalion on 2024/12/8.
//

import Foundation
import SwiftData
import SwiftUI

enum ProcessType: String, Codable {
    case application = "投递公司"
    case interview = "面试"
    case written = "笔试"
}

enum ProcessStatus: String, Codable {
    case pending = "待处理"
    case resume = "投递"
    case written = "笔试中"
    case interview1 = "一面"
    case interview2 = "二面"
    case interview3 = "三面+"
    case hrInterview = "HR面"
    case offer = "Offer"
    case failed = "未通过"
    
    var percentage: Int {
        switch self {
        case .pending: return 0
        case .resume: return 15
        case .written: return 30
        case .interview1: return 45
        case .interview2: return 60
        case .interview3: return 75
        case .hrInterview: return 85
        case .offer: return 100
        case .failed: return 0
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .failed: return .red
        case .offer: return .green
        default: return .blue
        }
    }
}

enum PinStatus: Int {
    case unpinned = 0
    case pinned = 1
}

@Model
final class Item {
    @Attribute(.unique) var id: String = UUID().uuidString
    var companyName: String = String()
    var companyIcon: String = String("building.2")
    var iconData: Data?
    var processType: ProcessType = ProcessType.application
    var currentStage: String = String()
    @Attribute private var statusRaw: String = ProcessStatus.pending.rawValue
    var nextStageDate: Date? = Optional<Date>.none
    var timestamp: Date = Date()
    @Attribute private var pinStatusRaw: Int = 0
    var recruitmentStage: RecruitmentStage?
    
    @Attribute var stages: [InterviewStageData] = []
    
    var status: ProcessStatus {
        get {
            ProcessStatus(rawValue: statusRaw) ?? .pending
        }
        set {
            statusRaw = newValue.rawValue
        }
    }
    
    var isPinned: Bool {
        get {
            PinStatus(rawValue: pinStatusRaw) == .pinned
        }
        set {
            pinStatusRaw = newValue ? PinStatus.pinned.rawValue : PinStatus.unpinned.rawValue
        }
    }
    
    init(companyName: String, 
         companyIcon: String = "building.2",
         iconData: Data? = nil,
         processType: ProcessType,
         currentStage: String,
         status: ProcessStatus = .pending,
         nextStageDate: Date? = nil,
         isPinned: Bool = false) {
        self.id = UUID().uuidString
        self.companyName = companyName
        self.companyIcon = companyIcon
        self.iconData = iconData
        self.processType = processType
        self.currentStage = currentStage
        self.statusRaw = status.rawValue
        self.nextStageDate = nextStageDate
        self.timestamp = Date()
        self.pinStatusRaw = isPinned ? PinStatus.pinned.rawValue : PinStatus.unpinned.rawValue
    }
}

extension Item: Comparable {
    static func < (lhs: Item, rhs: Item) -> Bool {
        if lhs.isPinned != rhs.isPinned {
            return lhs.isPinned
        }
        return lhs.timestamp < rhs.timestamp
    }
}
