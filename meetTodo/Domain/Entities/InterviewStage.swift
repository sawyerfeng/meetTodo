import SwiftUI

enum InterviewStage: String, Codable, Identifiable, CaseIterable {
    case resume = "投递"
    case written = "笔试"
    case interview = "面试"
    case hrInterview = "HR面"
    case offer = "Offer"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .resume: return "doc.text.fill"
        case .written: return "pencil.line"
        case .interview: return "person.fill"
        case .hrInterview: return "person.text.rectangle.fill"
        case .offer: return "checkmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .resume: return .blue
        case .written: return .orange
        case .interview: return .green
        case .hrInterview: return .purple
        case .offer: return .red
        }
    }
}

enum StageStatus: String {
    case pending = "待处理"
    case passed = "通过"
    case failed = "未通过"
    
    var color: Color {
        switch self {
        case .pending: return Color.gray.opacity(0.1)
        case .passed: return Color.green.opacity(0.1)
        case .failed: return Color.red.opacity(0.1)
        }
    }
} 