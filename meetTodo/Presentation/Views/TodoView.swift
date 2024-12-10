import SwiftUI
import SwiftData
import EventKit
import UserNotifications

struct TodoView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TodoViewModel
    
    @Query(
        filter: #Predicate<Item> { _ in true },
        sort: [.init(\Item.timestamp, order: .reverse)]
    ) private var items: [Item]
    
    init(modelContext: ModelContext) {
        self._viewModel = StateObject(wrappedValue: TodoViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            List {
                let todayTodos = viewModel.getTodayTodos(items: items)
                if todayTodos.isEmpty {
                    ContentUnavailableView("今日无待办", 
                        systemImage: "checkmark.circle",
                        description: Text("暂时没有面试或笔试安排")
                    )
                } else {
                    ForEach(todayTodos, id: \.1.id) { item, stageData in
                        NavigationLink {
                            CompanyDetailView(item: item, modelContext: modelContext)
                        } label: {
                            TodoRowView(item: item, stageData: stageData)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                Task {
                                    await viewModel.syncToCalendar(item: item, stageData: stageData)
                                }
                            } label: {
                                Label("添加到日历", systemImage: "calendar.badge.plus")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("今日待办")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.syncAllToCalendar()
                        }
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
            }
            .alert("需要权限", isPresented: $viewModel.showingSettingsAlert) {
                Button("取消", role: .cancel) { }
                Button("前往设置") {
                    viewModel.openSettings()
                }
            } message: {
                Text(viewModel.alertMessage)
            }
            .alert("同步日历", isPresented: $viewModel.showingAlert) {
                Button("确定") { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .task {
                // 在视图加载时检查并设置所有通知
                if viewModel.enableReminder {
                    await viewModel.setupAllNotifications()
                }
                // 清除已显示的通知
                await UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // 当应用回到前台时清除已显示的通知
                Task {
                    await UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                }
            }
        }
    }
}

#Preview {
    let modelContext = try! ModelContainer(for: Item.self).mainContext
    return TodoView(modelContext: modelContext)
        .modelContainer(try! ModelContainer(for: Item.self))
} 
