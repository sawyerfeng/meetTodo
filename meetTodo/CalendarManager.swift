import EventKit
import UIKit

class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    func checkAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async -> Bool {
        // 先检查当前权限状态
        let status = checkAuthorizationStatus()
        
        switch status {
        case .authorized:
            return true
            
        case .notDetermined:
            // 首次请求权限
            if #available(iOS 17.0, *) {
                return (try? await eventStore.requestFullAccessToEvents()) ?? false
            } else {
                return await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            }
            
        case .denied, .restricted:
            // 权限被拒绝，返回 false
            return false
            
        @unknown default:
            return false
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func hasExistingEvent(title: String, startDate: Date, endDate: Date) -> Bool {
        // 创建时间范围（以开始时间为中心，前后各1小时）
        let searchStart = Calendar.current.date(byAdding: .hour, value: -1, to: startDate)!
        let searchEnd = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        
        // 创建谓词来查找事件
        let predicate = eventStore.predicateForEvents(withStart: searchStart,
                                                    end: searchEnd,
                                                    calendars: nil)
        
        // 获取该时间范围内的所有事件
        let existingEvents = eventStore.events(matching: predicate)
        
        // 检查是否有相同标题且时间完全重叠的事件
        return existingEvents.contains { event in
            event.title == title &&
            abs(event.startDate.timeIntervalSince(startDate)) < 60 && // 开始时间相差不超过1分钟
            abs(event.endDate.timeIntervalSince(endDate)) < 60 // 结束时间相差不超过1分钟
        }
    }
    
    func addEvent(title: String, startDate: Date, notes: String?) async -> (Bool, String) {
        let status = checkAuthorizationStatus()
        
        // 如果权限被拒绝，返回错误信息
        guard status != .denied && status != .restricted else {
            return (false, "需要日历权限才能添加提醒，是否前往设置？")
        }
        
        // 请求权限
        guard await requestAccess() else {
            return (false, "获取日历权限失败")
        }
        
        // 计算结束时间（开始时间后1小时）
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        
        // 检查是否已存在相同的事件
        if hasExistingEvent(title: title, startDate: startDate, endDate: endDate) {
            return (false, "该时间段已存在相同的面试安排")
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // 添加提醒
        event.addAlarm(EKAlarm(relativeOffset: -3600)) // 1小时前提醒
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return (true, "已添加到系统日历")
        } catch {
            print("保存事件失败: \(error)")
            return (false, "添加失败：\(error.localizedDescription)")
        }
    }
} 