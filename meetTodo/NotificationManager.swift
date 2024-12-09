import UserNotifications
import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()
    
    func checkAuthorizationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("请求通知权限失败: \(error)")
            return false
        }
    }
    
    func scheduleNotification(for item: Item, stageData: InterviewStageData, minutesBefore: Int) async {
        // 检查是否启用了提醒
        guard UserDefaults.standard.bool(forKey: "enableReminder") else { return }
        
        // 获取提醒时间
        let notificationTime = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: stageData.date)!
        
        // 如果提醒时间已经过去，就不设置提醒
        guard notificationTime > Date() else { return }
        
        // 检查是否已经设置过这个通知
        let identifier = "interview-\(item.id)-\(stageData.id)"
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        guard !pendingRequests.contains(where: { $0.identifier == identifier }) else {
            return
        }
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "面试提醒"
        content.body = "\(item.companyName) 的\(stageData.stage)将在\(minutesBefore)分钟后开始"
        content.sound = .default
        content.badge = 1
        
        // 创建触发器
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // 创建通知请求
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 添加通知
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("成功设置通知：\(identifier) 在 \(notificationTime)")
        } catch {
            print("设置通知失败: \(error)")
        }
    }
    
    func removeNotification(for item: Item, stageData: InterviewStageData) {
        let identifier = "interview-\(item.id)-\(stageData.id)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func removeAllNotifications() async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()
        await center.removeAllDeliveredNotifications()
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // 检查所有待发送的通知
    func checkPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("当前待发送的通知数量：\(requests.count)")
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let date = trigger.nextTriggerDate() {
                print("通知 \(request.identifier) 将在 \(date) 触发")
            }
        }
    }
} 
