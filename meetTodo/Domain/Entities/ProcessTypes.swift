import Foundation
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