import SwiftUI
import SwiftData

struct TodoItem: Identifiable {
    let id: String
    let item: Item
    let date: Date
    let location: StageLocation?
}

class TodoViewModel: ObservableObject {
    private let modelContext: ModelContext
    @Published private(set) var todayItems: [TodoItem] = []
    @Published private(set) var futureItems: [TodoItem] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }
    
    func fetchItems() {
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\Item.nextStageDate, order: .forward)]
        )
        
        guard let items = try? modelContext.fetch(descriptor) else { return }
        
        var today: [TodoItem] = []
        var future: [TodoItem] = []
        let calendar = Calendar.current
        let now = Date()
        
        for item in items {
            guard let nextDate = item.nextStageDate else { continue }
            
            // 如果日期已经过去，跳过
            guard nextDate >= calendar.startOfDay(for: now) else { continue }
            
            // 从 stages 中找到对应的阶段
            guard let stageData = item.stages.first(where: { stage in
                guard let stageDate = stage.date as Date? else { return false }
                return calendar.isDate(stageDate, inSameDayAs: nextDate)
            }) else { continue }
            
            // 创建待办项
            let todoItem = TodoItem(
                id: "\(item.id)-\(stageData.id)",
                item: item,
                date: nextDate,
                location: stageData.location
            )
            
            // 根据日期分类
            if calendar.isDateInToday(nextDate) {
                today.append(todoItem)
            } else {
                future.append(todoItem)
            }
        }
        
        // 按时间排序
        todayItems = today.sorted { $0.date < $1.date }
        futureItems = future.sorted { $0.date < $1.date }
    }
} 