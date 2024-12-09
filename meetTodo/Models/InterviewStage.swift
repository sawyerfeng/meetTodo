import SwiftUI

/// 面试阶段
public enum InterviewStage: String, Codable, Identifiable, CaseIterable {
    case resume = "投递"
    case written = "笔试"
    case interview = "面试"
    case hrInterview = "HR面"
    case offer = "Offer"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .resume: return "doc.text.fill"
        case .written: return "pencil.line"
        case .interview: return "person.fill"
        case .hrInterview: return "person.text.rectangle.fill"
        case .offer: return "checkmark.seal.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .resume: return .blue
        case .written: return .orange
        case .interview: return .green
        case .hrInterview: return .purple
        case .offer: return .red
        }
    }
}

/// 阶段状态
public enum StageStatus: String {
    case pending = "待处理"
    case passed = "通过"
    case failed = "未通过"
    
    public var color: Color {
        switch self {
        case .pending: return Color.gray.opacity(0.1)
        case .passed: return Color.green.opacity(0.1)
        case .failed: return Color.red.opacity(0.1)
        }
    }
}

/// 地点类型
public enum LocationType: String, Codable, CaseIterable {
    case online = "线上"
    case offline = "线下"
}

/// 阶段地点
public struct StageLocation: Codable, Equatable {
    public var type: LocationType
    public var address: String // 线下地址或线上链接
    
    public init(type: LocationType, address: String) {
        self.type = type
        self.address = address
    }
    
    public static func == (lhs: StageLocation, rhs: StageLocation) -> Bool {
        return lhs.type == rhs.type && lhs.address == rhs.address
    }
} 