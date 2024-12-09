import SwiftUI
import SwiftData

/// 主内容视图的 ViewModel
/// 负责处理主列表的业务逻辑和状态管理
class ContentViewModel: ObservableObject {
    // MARK: - 属性
    
    /// 模型上下文，用于数据持久化
    private let modelContext: ModelContext
    
    /// 所有公司条目
    @Published private var items: [Item] = []
    
    /// 是否显示添加公司表单
    @Published var showingAddSheet = false
    
    /// 卡片状态
    @Published var cardStates: [ProcessType: CardState] = [
        .application: .total,
        .interview: .total,
        .written: .total
    ]
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameters:
    ///   - modelContext: SwiftData 模型上下文
    ///   - items: 初始数据项
    init(modelContext: ModelContext, items: [Item] = []) {
        self.modelContext = modelContext
        self.items = items
        fetchItems()
    }
    
    // MARK: - 公共方法
    
    /// 获取数据项
    func fetchItems() {
        do {
            items = try modelContext.fetch(FetchDescriptor<Item>())
        } catch {
            print("Error fetching items: \(error)")
        }
    }
    
    /// 获取指定类型的数据项
    /// - Parameter type: 流程类型
    /// - Returns: 数据项列表
    func getItems(for type: ProcessType) -> [Item] {
        items.filter { $0.processType == type }
            .sorted()
    }
    
    /// 获取笔试数量
    /// - Returns: 笔试数量
    func getWrittenCount() -> Int {
        items.reduce(0) { count, item in
            count + (item.stages.contains { $0.stage == InterviewStage.written.rawValue } ? 1 : 0)
        }
    }
    
    /// 获取面试数量
    /// - Returns: 面试数量
    func getInterviewCount() -> Int {
        items.reduce(0) { count, item in
            count + (item.stages.contains { stage in
                [InterviewStage.interview.rawValue, 
                 InterviewStage.hrInterview.rawValue].contains(stage.stage)
            } ? 1 : 0)
        }
    }
    
    /// 更新数据项
    /// - Parameter newItems: 新的数据项列表
    func updateItems(_ newItems: [Item]) {
        items = newItems
    }
    
    /// 删除公司
    /// - Parameter item: 要删除的公司
    func deleteItem(_ item: Item) {
        modelContext.delete(item)
    }
    
    /// 切换置顶状态
    /// - Parameter item: 要切换的公司
    func togglePin(_ item: Item) {
        item.isPinned.toggle()
    }
    
    /// 更新卡片状态
    /// - Parameters:
    ///   - type: 流程类型
    ///   - animate: 是否使用动画
    func updateCardState(for type: ProcessType, animate: Bool = true) {
        let currentState = cardStates[type] ?? .total
        let nextRawValue = (currentState.rawValue + 1) % 3
        if let nextState = CardState(rawValue: nextRawValue) {
            if animate {
                withAnimation {
                    cardStates[type] = nextState
                }
            } else {
                cardStates[type] = nextState
            }
        }
    }
    
    /// 获取统计数据
    /// - Parameter type: 流程类型
    /// - Returns: 统计数据
    func getStatistics(for type: ProcessType) -> (total: Int, passed: Int, rate: Int) {
        let typeItems = items.filter { $0.processType == type }
        let total = typeItems.count
        let passed = typeItems.filter { $0.status == .success }.count
        let rate = total > 0 ? Int(Double(passed) / Double(total) * 100) : 0
        return (total, passed, rate)
    }
    
    /// 获取显示的统计数据
    /// - Parameter type: 流程类型
    /// - Returns: 显示的数值
    func getDisplayValue(for type: ProcessType) -> String {
        let stats = getStatistics(for: type)
        switch cardStates[type] {
        case .total: return "\(stats.total)"
        case .passed: return "\(stats.passed)"
        case .rate: return "\(stats.rate)%"
        case .none: return "0"
        }
    }
} 