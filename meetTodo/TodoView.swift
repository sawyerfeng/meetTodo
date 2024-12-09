import SwiftUI
import SwiftData
import EventKit
import UserNotifications

struct TodoView: View {
    @Query(
        filter: #Predicate<Item> { _ in true },
        sort: [.init(\Item.timestamp, order: .reverse)]
    ) private var items: [Item]
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSettingsAlert = false
    @AppStorage("enableReminder") private var enableReminder = true
    @AppStorage("reminderMinutes") private var reminderMinutes = 60
    
    var todayTodos: [(Item, InterviewStageData)] {
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
    
    var body: some View {
        NavigationStack {
            List {
                if todayTodos.isEmpty {
                    ContentUnavailableView("今日无待办", 
                        systemImage: "checkmark.circle",
                        description: Text("暂时没有面试或笔试安排")
                    )
                } else {
                    ForEach(todayTodos, id: \.1.id) { item, stageData in
                        NavigationLink {
                            CompanyDetailView(item: item)
                        } label: {
                            TodoRowView(item: item, stageData: stageData)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                Task {
                                    await syncToCalendar(item: item, stageData: stageData)
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
                            await syncAllToCalendar()
                        }
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
            }
            .alert("需要权限", isPresented: $showingSettingsAlert) {
                Button("取消", role: .cancel) { }
                Button("前往设置") {
                    CalendarManager.shared.openSettings()
                }
            } message: {
                Text(alertMessage)
            }
            .alert("同步日历", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
            .task {
                // 在视图加载时检查并设置所有通知
                if enableReminder {
                    await setupAllNotifications()
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
            .onChange(of: enableReminder) { _, newValue in
                if newValue {
                    // 当开启提醒时，设置所有通知
                    Task {
                        await setupAllNotifications()
                    }
                } else {
                    // 当关闭提醒时，移除所有通知
                    Task {
                        await NotificationManager.shared.removeAllNotifications()
                    }
                }
            }
            .onChange(of: reminderMinutes) { _, _ in
                // 当提醒时间改变时，重新设置所有通知
                if enableReminder {
                    Task {
                        await NotificationManager.shared.removeAllNotifications()
                        await setupAllNotifications()
                    }
                }
            }
        }
    }
    
    private func setupAllNotifications() async {
        for (item, stageData) in todayTodos {
            await NotificationManager.shared.scheduleNotification(
                for: item,
                stageData: stageData,
                minutesBefore: reminderMinutes
            )
        }
        // 检查通知是否设置成功
        await NotificationManager.shared.checkPendingNotifications()
    }
    
    private func syncToCalendar(item: Item, stageData: InterviewStageData) async {
        // 检查日历权限状态
        let authStatus = CalendarManager.shared.checkAuthorizationStatus()
        
        switch authStatus {
        case .notDetermined:
            // 首次请求权限
            if await CalendarManager.shared.requestAccess() {
                // 获得权限后，添加日历事件
                let (_, message) = await CalendarManager.shared.addEvent(
                    title: "\(item.companyName) - \(stageData.stage)",
                    startDate: stageData.date,
                    notes: stageData.note
                )
                await MainActor.run {
                    alertMessage = message
                    showingAlert = true
                }
            } else {
                await MainActor.run {
                    alertMessage = "需要日历权限才能添加提醒，是否前往设置？"
                    showingSettingsAlert = true
                }
            }
            
        case .authorized:
            // 已有权限，直接添加日历事件
            let (_, message) = await CalendarManager.shared.addEvent(
                title: "\(item.companyName) - \(stageData.stage)",
                startDate: stageData.date,
                notes: stageData.note
            )
            await MainActor.run {
                alertMessage = message
                showingAlert = true
            }
            
        case .denied, .restricted:
            // 权限被拒绝，显示设置引导
            await MainActor.run {
                alertMessage = "需要日历权限才能添加提醒，是否前往设置？"
                showingSettingsAlert = true
            }
            
        case .fullAccess, .writeOnly:
            // 已有权限，直接添加日历事件
            let (_, message) = await CalendarManager.shared.addEvent(
                title: "\(item.companyName) - \(stageData.stage)",
                startDate: stageData.date,
                notes: stageData.note
            )
            await MainActor.run {
                alertMessage = message
                showingAlert = true
            }
            
        @unknown default:
            await MainActor.run {
                alertMessage = "日历权限状态未知"
                showingAlert = true
            }
        }
    }
    
    private func syncAllToCalendar() async {
        // 检查日历权限状态
        let authStatus = CalendarManager.shared.checkAuthorizationStatus()
        
        switch authStatus {
        case .notDetermined:
            // 首次请求权限
            if await CalendarManager.shared.requestAccess() {
                await syncAllEvents()
            } else {
                await MainActor.run {
                    alertMessage = "需要日历权限才能添加提醒，是否前往设置？"
                    showingSettingsAlert = true
                }
            }
            
        case .authorized:
            // 已有权限，直接同步所有事件
            await syncAllEvents()
            
        case .denied, .restricted:
            // 权限被拒绝，显示设置引导
            await MainActor.run {
                alertMessage = "需要日历权限才能添加提醒，是否前往设置？"
                showingSettingsAlert = true
            }
            
        case .fullAccess, .writeOnly:
            // 已有权限，直接同步所有事件
            await syncAllEvents()
            
        @unknown default:
            await MainActor.run {
                alertMessage = "日历权限状态未知"
                showingAlert = true
            }
        }
    }
    
    private func syncAllEvents() async {
        var successCount = 0
        
        for (item, stageData) in todayTodos {
            let (success, _) = await CalendarManager.shared.addEvent(
                title: "\(item.companyName) - \(stageData.stage)",
                startDate: stageData.date,
                notes: stageData.note
            )
            
            if success {
                successCount += 1
            }
        }
        
        await MainActor.run {
            alertMessage = "成功同步 \(successCount) 个待办到系统日历"
            showingAlert = true
        }
    }
}

struct TodoRowView: View {
    let item: Item
    let stageData: InterviewStageData
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: stageData.date)
    }
    
    var stageName: String {
        if stageData.stage == InterviewStage.interview.rawValue,
           let round = stageData.interviewRound {
            return "第\(round)面"
        }
        return InterviewStage(rawValue: stageData.stage)?.rawValue ?? stageData.stage
    }
    
    var stageIcon: String {
        if let stage = InterviewStage(rawValue: stageData.stage) {
            return stage.icon
        }
        return "questionmark.circle"
    }
    
    var stageColor: Color {
        if let stage = InterviewStage(rawValue: stageData.stage) {
            return stage.color
        }
        return .gray
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: stageIcon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(stageColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.companyName)
                    .font(.headline)
                Text(stageName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timeString)
                .font(.title3.bold())
                .foregroundColor(stageColor)
                .frame(minWidth: 60)
        }
        .padding(.vertical, 8)
    }
} 
