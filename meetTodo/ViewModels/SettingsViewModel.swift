import SwiftUI
import EventKit

/// 权限状态
enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
}

/// 设置视图的 ViewModel
class SettingsViewModel: ObservableObject {
    // MARK: - 属性
    
    /// 通知权限状态
    @Published var notificationStatus: PermissionStatus = .notDetermined
    
    /// 日历权限状态
    @Published var calendarStatus: PermissionStatus = .notDetermined
    
    /// 是否启用通知
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    /// 通知提前时间（分钟）
    @Published var notificationMinutes: Int {
        didSet {
            UserDefaults.standard.set(notificationMinutes, forKey: "notificationMinutes")
        }
    }
    
    /// 是否启用日历同步
    @Published var calendarSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(calendarSyncEnabled, forKey: "calendarSyncEnabled")
        }
    }
    
    /// 选中的日历ID
    @Published var selectedCalendarId: String {
        didSet {
            UserDefaults.standard.set(selectedCalendarId, forKey: "selectedCalendarId")
        }
    }
    
    /// 可用的日历列表
    @Published var calendars: [EKCalendar] = []
    
    /// 是否显示权限提示
    @Published var showingPermissionAlert = false
    
    /// 权限提示信息
    @Published var permissionAlertMessage = ""
    
    /// 是否可以启用通知
    var canEnableNotifications: Bool {
        notificationStatus == .authorized
    }
    
    /// 是否可以启用日历同步
    var canEnableCalendarSync: Bool {
        calendarStatus == .authorized
    }
    
    /// App 版本号
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
    }
    
    // MARK: - 初始化方法
    
    init() {
        // 从 UserDefaults 读取设置
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.notificationMinutes = UserDefaults.standard.integer(forKey: "notificationMinutes")
        self.calendarSyncEnabled = UserDefaults.standard.bool(forKey: "calendarSyncEnabled")
        self.selectedCalendarId = UserDefaults.standard.string(forKey: "selectedCalendarId") ?? ""
        
        // 如果没有设置过通知时间，默认为15分钟
        if self.notificationMinutes == 0 {
            self.notificationMinutes = 15
        }
        
        // 检查权限状态
        Task {
            await checkPermissions()
        }
    }
    
    // MARK: - 公共方法
    
    /// 检查权限状态
    @MainActor
    func checkPermissions() async {
        // 检查通知权限
        let notificationStatus = await NotificationManager.shared.checkAuthorizationStatus()
        switch notificationStatus {
        case .authorized:
            self.notificationStatus = .authorized
        case .denied:
            self.notificationStatus = .denied
            if self.notificationsEnabled {
                self.notificationsEnabled = false
            }
        case .notDetermined:
            self.notificationStatus = .notDetermined
        default:
            self.notificationStatus = .denied
        }
        
        // 检查日历权限
        let calendarStatus = await CalendarManager.shared.checkAuthorizationStatus()
        switch calendarStatus {
        case .authorized:
            self.calendarStatus = .authorized
            self.loadCalendars()
        case .denied:
            self.calendarStatus = .denied
            if self.calendarSyncEnabled {
                self.calendarSyncEnabled = false
            }
        case .notDetermined:
            self.calendarStatus = .notDetermined
        default:
            self.calendarStatus = .denied
        }
    }
    
    /// 请求通知权限
    func requestNotificationPermission() {
        Task { @MainActor in
            let granted = await NotificationManager.shared.requestAuthorization()
            self.notificationStatus = granted ? .authorized : .denied
            if !granted {
                self.showPermissionAlert(message: "通知权限申请被拒绝，如需开启请前往系统设置")
            }
        }
    }
    
    /// 请求日历权限
    func requestCalendarPermission() {
        Task { @MainActor in
            let granted = await CalendarManager.shared.requestAccess()
            self.calendarStatus = granted ? .authorized : .denied
            if granted {
                self.loadCalendars()
            } else {
                self.showPermissionAlert(message: "日历权限申请被拒绝，如需开启请前往系统设置")
            }
        }
    }
    
    /// 打开系统设置
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    /// 处理通知开关变化
    func handleNotificationToggle() {
        if notificationsEnabled && notificationStatus != .authorized {
            notificationsEnabled = false
            showPermissionAlert(message: "请先授权通知权限")
        }
    }
    
    /// 处理日历同步开关变化
    func handleCalendarSyncToggle() {
        if calendarSyncEnabled && calendarStatus != .authorized {
            calendarSyncEnabled = false
            showPermissionAlert(message: "请先授权日历权限")
        }
    }
    
    // MARK: - 私有方法
    
    /// 加载可用的日历列表
    private func loadCalendars() {
        calendars = CalendarManager.shared.getCalendars()
        
        // 如果没有选择过日历，默认选择第一个
        if selectedCalendarId.isEmpty, let firstCalendar = calendars.first {
            selectedCalendarId = firstCalendar.calendarIdentifier
        }
    }
    
    /// 显示权限提示
    private func showPermissionAlert(message: String) {
        permissionAlertMessage = message
        showingPermissionAlert = true
    }
} 