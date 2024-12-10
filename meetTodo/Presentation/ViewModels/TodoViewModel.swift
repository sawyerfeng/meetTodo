import SwiftUI
import SwiftData

@MainActor
class TodoViewModel: ObservableObject {
    private let modelContext: ModelContext
    private let notificationService: NotificationService
    private let calendarService: CalendarService
    
    @Published var showingAddSheet = false
    @Published var showingCalendarAlert = false
    @Published var showingNotificationAlert = false
    @Published var showingSettingsAlert = false
    @Published var selectedItem: Item?
    @Published var alertMessage = ""
    @Published var showingAlert = false
    
    @AppStorage("enableReminder") var enableReminder = true
    @AppStorage("reminderMinutes") var reminderMinutes = 60
    
    init(modelContext: ModelContext,
         notificationService: NotificationService = DefaultNotificationService.shared,
         calendarService: CalendarService = DefaultCalendarService.shared) {
        self.modelContext = modelContext
        self.notificationService = notificationService
        self.calendarService = calendarService
    }
    
    func getTodayTodos(items: [Item]) -> [(Item, InterviewStageData)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return items.flatMap { item in
            item.stages.filter { stageData in
                let stageDate = calendar.startOfDay(for: stageData.date)
                return stageDate >= today && stageDate < tomorrow &&
                       (stageData.stage == InterviewStage.interview.rawValue ||
                        stageData.stage == InterviewStage.written.rawValue ||
                        stageData.stage == InterviewStage.hrInterview.rawValue) &&
                       stageData.status == StageStatus.pending.rawValue
            }.map { (item, $0) }
        }
    }
    
    func setupAllNotifications() async {
        let granted = try? await notificationService.requestAuthorization()
        guard granted == true else {
            showingNotificationAlert = true
            return
        }
        
        await notificationService.removeAllNotifications()
        
        let descriptor = FetchDescriptor<Item>()
        let items = (try? modelContext.fetch(descriptor)) ?? []
        
        for item in items {
            for stageData in item.stages where stageData.status == StageStatus.pending.rawValue {
                await notificationService.scheduleNotification(
                    for: item,
                    stageData: stageData,
                    minutesBefore: reminderMinutes
                )
            }
        }
    }
    
    func syncToCalendar(item: Item, stageData: InterviewStageData) async {
        do {
            let granted = try await calendarService.requestAccess()
            guard granted else {
                alertMessage = "需要日历权限才能添加提醒，是否前往设置？"
                showingSettingsAlert = true
                return
            }
            
            let title = "\(item.companyName) \(stageData.stage)"
            let eventId = try await calendarService.addEvent(
                title: title,
                startDate: stageData.date,
                location: stageData.location?.address
            )
            
            // 保存事件标识符
            var eventIds = item.calendarEventIdentifiers
            eventIds.append(eventId)
            item.calendarEventIdentifiers = eventIds
            try? modelContext.save()
            
            alertMessage = "已添加到系统日历"
            showingAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    func syncAllToCalendar() async {
        do {
            let granted = try await calendarService.requestAccess()
            guard granted else {
                alertMessage = "需要日历权限才能添加提醒，是否前往设置？"
                showingSettingsAlert = true
                return
            }
            
            let descriptor = FetchDescriptor<Item>()
            let items = (try? modelContext.fetch(descriptor)) ?? []
            var addedCount = 0
            
            for (item, stageData) in getTodayTodos(items: items) {
                let title = "\(item.companyName) \(stageData.stage)"
                let eventId = try await calendarService.addEvent(
                    title: title,
                    startDate: stageData.date,
                    location: stageData.location?.address
                )
                
                // 保存事件标识符
                var eventIds = item.calendarEventIdentifiers
                eventIds.append(eventId)
                item.calendarEventIdentifiers = eventIds
                try? modelContext.save()
                
                addedCount += 1
            }
            
            alertMessage = "已添加 \(addedCount) 个日程到系统日历"
            showingAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    func openSettings() {
        calendarService.openSettings()
    }
} 