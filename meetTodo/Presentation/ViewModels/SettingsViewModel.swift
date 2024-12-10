import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    private let notificationService: NotificationService
    private let calendarService: CalendarService
    
    @AppStorage("enableReminder") var enableReminder = true
    @AppStorage("reminderMinutes") var reminderMinutes = 60
    
    @Published var showingNotificationAlert = false
    @Published var alertMessage = ""
    
    init(notificationService: NotificationService = DefaultNotificationService.shared,
         calendarService: CalendarService = DefaultCalendarService.shared) {
        self.notificationService = notificationService
        self.calendarService = calendarService
        
        Task {
            await checkNotificationPermission()
        }
    }
    
    func handleReminderToggle(_ newValue: Bool) async {
        if newValue {
            // 当用户开启提醒时，检查权限
            let hasPermission = await notificationService.checkAuthorizationStatus()
            
            if !hasPermission {
                // 如果没有权限，请求权限
                let granted = try? await notificationService.requestAuthorization()
                
                if granted == true {
                    alertMessage = "通知权限已开启"
                } else {
                    alertMessage = "需要在系统设置中开启通知权限"
                    enableReminder = false
                }
                showingNotificationAlert = true
            }
        } else {
            // 当用户关闭提醒时，移除所有待发送的通知
            await notificationService.removeAllNotifications()
        }
    }
    
    private func checkNotificationPermission() async {
        if enableReminder {
            let hasPermission = await notificationService.checkAuthorizationStatus()
            
            if !hasPermission {
                enableReminder = false
                alertMessage = "需要开启通知权限才能使用提醒功能"
                showingNotificationAlert = true
            }
        }
    }
    
    func openNotificationSettings() {
        notificationService.openSettings()
    }
    
    func openCalendarSettings() {
        calendarService.openSettings()
    }
} 