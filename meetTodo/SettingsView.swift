import SwiftUI
import UserNotifications

@MainActor
struct SettingsView: View {
    @AppStorage("enableReminder") private var enableReminder = true
    @AppStorage("reminderMinutes") private var reminderMinutes = 60
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let reminderOptions = [
        15: "15分钟前",
        30: "30分钟前",
        60: "1小时前",
        120: "2小时前",
        180: "3小时前",
        240: "4小时前",
        1440: "1天前"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("开启面试提醒", isOn: $enableReminder)
                        .tint(.blue)
                        .onChange(of: enableReminder) { _, newValue in
                            if newValue {
                                // 当用户开启提醒时，检查权限
                                Task {
                                    let hasPermission = try? await withCheckedThrowingContinuation { continuation in
                                        Task {
                                            let status = await NotificationManager.shared.checkAuthorizationStatus()
                                            continuation.resume(returning: status)
                                        }
                                    }
                                    
                                    if hasPermission == false {
                                        // 如果没有权限，请求权限
                                        let granted = try? await withCheckedThrowingContinuation { continuation in
                                            Task {
                                                let status = await NotificationManager.shared.requestAuthorization()
                                                continuation.resume(returning: status)
                                            }
                                        }
                                        
                                        if granted == true {
                                            alertMessage = "通知权限已开启"
                                        } else {
                                            alertMessage = "需要在系统设置中开启通知权限"
                                            enableReminder = false
                                        }
                                        showingAlert = true
                                    }
                                }
                            } else {
                                // 当用户关闭提醒时，移除所有待发送的通知
                                NotificationManager.shared.removeAllNotifications()
                            }
                        }
                    
                    if enableReminder {
                        Picker("提前提醒时间", selection: $reminderMinutes) {
                            ForEach(Array(reminderOptions.keys).sorted(), id: \.self) { minutes in
                                Text(reminderOptions[minutes] ?? "")
                                    .tag(minutes)
                            }
                        }
                    }
                } header: {
                    Text("提醒设置")
                } footer: {
                    Text("关闭后将不会收到面试日程的系统提醒")
                }
                
                Section {
                    Button {
                        NotificationManager.shared.openSettings()
                    } label: {
                        HStack {
                            Text("通知权限设置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button {
                        CalendarManager.shared.openSettings()
                    } label: {
                        HStack {
                            Text("日历权限设置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("系统设置")
                } footer: {
                    Text("管理应用的系统权限")
                }
            }
            .navigationTitle("设置")
            .alert("通知设置", isPresented: $showingAlert) {
                Button("取消", role: .cancel) { }
                Button("前往设置") {
                    NotificationManager.shared.openSettings()
                }
            } message: {
                Text(alertMessage)
            }
            .task {
                if enableReminder {
                    let hasPermission = try? await withCheckedThrowingContinuation { continuation in
                        Task {
                            let status = await NotificationManager.shared.checkAuthorizationStatus()
                            continuation.resume(returning: status)
                        }
                    }
                    
                    if hasPermission == false {
                        enableReminder = false
                        alertMessage = "需要开启通知权限才能使用提醒功能"
                        showingAlert = true
                    }
                }
            }
        }
    }
} 
