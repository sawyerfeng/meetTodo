import SwiftUI
import SwiftData

/// 统计数据
struct StatisticsData {
    let total: Int
    let passed: Int
    let rate: Int
}

/// 统计视图的 ViewModel
class StatisticsViewModel: ObservableObject {
    // MARK: - 属性
    
    /// 统计数据
    @Published private(set) var statistics: [ProcessType: StatisticsData] = [:]
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameter items: 数据项列表
    init(items: [Item]) {
        updateItems(items)
    }
    
    // MARK: - 公共方法
    
    /// 更新数据项
    /// - Parameter items: 新的数据项列表
    func updateItems(_ items: [Item]) {
        // 按流程类型分组
        let groupedItems = Dictionary(grouping: items) { $0.processType }
        
        // 计算每种类型的统计数据
        statistics = groupedItems.mapValues { items in
            let total = items.count
            let passed = items.filter { $0.status == .success }.count
            let rate = total > 0 ? Int(Double(passed) / Double(total) * 100) : 0
            return StatisticsData(total: total, passed: passed, rate: rate)
        }
    }
    
    /// 获取显示的统计数据
    /// - Parameters:
    ///   - type: 流程类型
    ///   - state: 卡片状态
    /// - Returns: 显示的数值
    func getDisplayValue(for type: ProcessType, state: CardState) -> String {
        guard let stats = statistics[type] else { return "0" }
        
        switch state {
        case .total: return "\(stats.total)"
        case .passed: return "\(stats.passed)"
        case .rate: return "\(stats.rate)%"
        }
    }
} 